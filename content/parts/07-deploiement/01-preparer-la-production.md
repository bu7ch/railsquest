---
title: "Préparer l'application pour la production"
exercises:
  - key: "7.1"
    title: "Repérer le Dockerfile généré par rails new"
  - key: "7.2"
    title: "Chiffrer un secret avec les credentials Rails"
  - key: "7.3"
    title: "Lancer l'application en mode production en local"
  - key: "7.4"
    title: "Comprendre le healthcheck /up"
  - key: "7.5"
    title: "Vérifier la configuration multi-bases de production"
---

# Préparer l'application pour la production

Jusqu'ici, `donor_crm` n'a tourné qu'en développement : rechargement à
chaud (partie 0), base SQLite locale, jobs exécutés dans le même
processus (partie 6). La production a des exigences différentes — le
code doit tourner dans un environnement reproductible, les secrets ne
doivent jamais apparaître en clair dans le dépôt, et rien ne doit
dépendre d'un rechargement à chaud qui n'existe plus. `rails new`
prépare déjà l'essentiel de ce terrain depuis la toute première
commande de la partie 0 ; ce chapitre l'explore.

## Le Dockerfile généré

```bash
ls Dockerfile .dockerignore
```

Ces deux fichiers existent depuis `rails new donor_crm
--database=sqlite3` (partie 0), avant même qu'une seule ligne de code
métier n'ait été écrite. Le `Dockerfile` décrit, étape par étape,
comment construire une image contenant Ruby, les gems du `Gemfile.lock`
(partie 0), et l'application elle-même — la même image tournera en
production que celle testée en local, éliminant la classe de bugs
« ça marche chez moi ».

```dockerfile
# Dockerfile (extrait)
FROM ruby:3.4-slim AS base

WORKDIR /rails

# ...

RUN bundle install

COPY . .
RUN bin/rails assets:precompile
```

`.dockerignore` exclut du build tout ce qui n'a pas besoin d'y être —
`.git/`, `log/`, `tmp/`, `test/` — pour garder l'image légère et éviter
d'y faire fuiter des fichiers de développement.

## Chiffrer les secrets

Un `SECRET_KEY_BASE`, une clé d'API, un mot de passe SMTP : aucun de
ces secrets ne doit jamais être écrit en clair dans un fichier versionné
par Git. Rails fournit un mécanisme dédié depuis `rails new` :

```bash
bin/rails credentials:edit
```

Cette commande ouvre `config/credentials.yml.enc` dans l'éditeur
défini par `$EDITOR`, déchiffré temporairement grâce à
`config/master.key` — un fichier volontairement absent de Git
(`.gitignore` l'exclut dès la génération du projet). Le fichier
`.enc`, lui, est chiffré et peut être commité sans risque : sans
`master.key`, il est illisible.

```yaml
# contenu déchiffré de config/credentials.yml.enc
donation_mailer:
  from: dons@association.org
```

En production, `master.key` n'est jamais versionné : il est copié
séparément sur le serveur, ou fourni via la variable d'environnement
`RAILS_MASTER_KEY` — c'est ce fichier, et lui seul, qui permet à
l'application déployée de déchiffrer ses propres secrets.

## Lancer l'application comme en production

Le mode production diffère du mode développement sur plusieurs points
qu'aucun test en local ne couvre par défaut : rechargement à chaud
désactivé (partie 0), assets précompilés une fois pour toutes plutôt
que recalculés à chaque requête, erreurs jamais affichées en détail à
l'utilisateur.

```bash
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails db:prepare
RAILS_ENV=production bin/rails server
```

`assets:precompile` calcule une fois les noms de fichiers avec
empreinte (Propshaft, déjà rencontré en partie 0 pour `public/`) que le
navigateur mettra en cache indéfiniment. Tester ce mode en local, avant
tout déploiement, révèle des erreurs — un asset manquant, une variable
d'environnement oubliée — qu'aucun test en mode développement n'aurait
révélées, puisque le mode développement recalcule tout à la volée et
masque ainsi ces manques.

## Le healthcheck

`bin/rails routes` (partie 0) affiche depuis toujours une route
`/up`, sans qu'aucune partie n'ait encore expliqué à quoi elle sert.

```ruby
# config/routes.rb, générée par rails new
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  # ...
end
```

Cette route répond `200 OK` si l'application a démarré sans erreur —
rien de plus, aucune base de données interrogée, aucune authentification
requise (elle ne doit surtout pas se heurter au
`require_authentication` par défaut de la partie 3). C'est exactement
ce genre de route qu'un outil de déploiement interroge en boucle après
un déploiement, pour décider si la nouvelle version peut recevoir du
trafic ou si elle doit être annulée.

## Quatre bases de données, une par responsabilité

Rails 8, la version utilisée tout au long de ce cours, configure par
défaut trois usages internes de SQLite en production, en plus de la
base applicative principale — Solid Cable (partie 5) et Solid Queue
(partie 6), déjà rencontrés, n'inventent pas de nouvelle base à la
volée : ils utilisent chacun la leur :

```yaml
# config/database.yml (extrait)
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
  cable:
    <<: *default
    database: storage/production_cable.sqlite3
    migrations_paths: db/cable_migrate
```

`primary` porte `Donor`, `Campaign`, `Donation`, `User`, `Session` —
tout ce que ce cours a modélisé depuis la partie 1. `queue` et `cable`
isolent respectivement les jobs Active Job (Solid Queue, partie 6) et
la diffusion Turbo (Solid Cable, partie 5) dans leurs propres fichiers,
pour qu'une opération de maintenance sur l'un ne verrouille jamais les
autres. `cache` sert Solid Cache, le cache Rails par défaut
(`Rails.cache`) — ce cours n'a jamais eu besoin d'y stocker quoi que ce
soit explicitement, mais Rails 8 le configure d'office avec sa propre
base, prêt à servir dès qu'un cache de fragment ou de requête en aurait
besoin.

## Exercices

**7.1 — Repérer le Dockerfile généré par `rails new`**

Ouvrez `Dockerfile` et `.dockerignore` à la racine de `donor_crm`.
Dans `NOTES.md` (partie 0), notez trois fichiers ou dossiers exclus par
`.dockerignore` et pourquoi chacun n'a rien à faire dans l'image de
production.

**7.2 — Chiffrer un secret avec les credentials Rails**

Lancez `bin/rails credentials:edit` et ajoutez la clé
`donation_mailer: { from: "dons@association.org" }`. Vérifiez depuis
la console que `Rails.application.credentials.dig(:donation_mailer,
:from)` renvoie bien cette valeur. Confirmez que `config/master.key`
n'apparaît pas dans `git status` en tant que fichier suivi.

**7.3 — Lancer l'application en mode production en local**

Exécutez les trois commandes ci-dessus. Si le serveur refuse de
démarrer (`SECRET_KEY_BASE` manquante hors présence de
`master.key`), lisez le message d'erreur et corrigez avant de
continuer — c'est exactement ce genre d'échec qu'il vaut mieux
rencontrer en local qu'en plein déploiement.

**7.4 — Comprendre le healthcheck `/up`**

Avec le serveur du mode production toujours lancé, visitez
`/up` et vérifiez la réponse `200 OK`. Dans `NOTES.md`, expliquez
pourquoi cette route ne doit jamais exiger d'authentification, même
si toutes les autres routes de `donor_crm` le font par défaut depuis
la partie 3.

**7.5 — Vérifier la configuration multi-bases de production**

Ouvrez `config/database.yml` et repérez les quatre entrées (`primary`,
`cache`, `queue`, `cable`) sous `production:`. Dans `NOTES.md`,
associez `queue` et `cable` à la partie du cours qui a fait apparaître
la fonctionnalité correspondante pour la première fois (Solid Queue ou
Solid Cable), et écrivez une phrase sur ce à quoi `cache` sert, même si
ce cours ne l'a jamais utilisé explicitement.
