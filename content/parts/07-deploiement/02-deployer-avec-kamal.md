---
title: "Déployer avec Kamal"
exercises:
  - key: "7.6"
    title: "Lire et annoter config/deploy.yml"
  - key: "7.7"
    title: "Vérifier que .kamal/secrets ne contient aucune valeur en clair"
  - key: "7.8"
    title: "Comprendre le rôle de Thruster devant Puma"
  - key: "7.9"
    title: "Rendre l'expéditeur des emails configurable par environnement"
  - key: "7.10"
    title: "Rédiger la checklist de mise en production"
---

# Déployer avec Kamal

Le chapitre précédent a préparé `donor_crm` pour tourner en production
(image Docker, secrets chiffrés, healthcheck). Il reste à l'envoyer
réellement sur un serveur. Kamal — inclus par défaut depuis `rails new`,
comme le Dockerfile du chapitre précédent — construit l'image, la pousse
vers un registre, et l'exécute sur un ou plusieurs serveurs, sans
nécessiter d'infrastructure plus lourde qu'une machine Linux accessible
en SSH.

## `config/deploy.yml`

Ce fichier, déjà présent depuis la partie 0, décrit tout ce que Kamal a
besoin de savoir pour déployer :

```yaml
# config/deploy.yml (extrait)
service: donor_crm

image: votre-compte/donor_crm

servers:
  web:
    - 192.0.2.10

proxy:
  ssl: true
  host: donor-crm.exemple.org

registry:
  username: votre-compte
  password:
    - KAMAL_REGISTRY_PASSWORD
```

`service` nomme le conteneur ; `image` désigne son nom sur le registre
(Docker Hub ou un registre privé) ; `servers` liste les machines cibles
— une seule ici, plusieurs pour répartir la charge ; `proxy` configure
kamal-proxy, qui obtient et renouvelle automatiquement un certificat
HTTPS pour le domaine indiqué ; `registry` authentifie l'envoi de
l'image, sans jamais écrire le mot de passe en clair dans ce fichier
versionné — `KAMAL_REGISTRY_PASSWORD` est lu depuis l'environnement,
exactement comme `RAILS_MASTER_KEY` au chapitre précédent.

## Les secrets de déploiement

```bash
# .kamal/secrets
KAMAL_REGISTRY_PASSWORD=$(cat ~/.docker-registry-password)
RAILS_MASTER_KEY=$(cat config/master.key)
```

Contrairement à `config/master.key` (chapitre précédent), `.kamal/secrets`
est fait pour être commité : il ne contient jamais une vraie valeur,
seulement des indirections (`$(cat ...)`, une variable d'environnement,
un appel à un gestionnaire de mots de passe) que Kamal résout au moment
du déploiement. Le vrai secret, lui, ne transite jamais par un fichier
versionné : `config/master.key` reste sur le poste de développement et
sur le serveur, jamais dans Git.

## Thruster, devant Puma

```bash
# bin/thrust (extrait), généré par rails new
exec thrust bin/rails server
```

Puma (le serveur d'application Rails, déjà actif à chaque `bin/rails
server` depuis la partie 0) sait répondre aux requêtes ; il ne sait pas
nativement gérer HTTP/2, compresser les réponses, ou mettre en cache
les assets précompilés (chapitre précédent) avec des en-têtes HTTP
adaptés. Thruster s'intercale devant Puma pour ces tâches — le
`Dockerfile` généré démarre `bin/thrust` plutôt que `bin/rails server`
directement, sans qu'aucune ligne de code applicatif n'ait besoin de le
savoir.

## Composer un réglage existant plutôt que le remplacer

L'expéditeur des emails (partie 6) est actuellement une valeur fixe.
Un compte associatif réel a souvent une adresse différente en test et
en production ; les credentials chiffrées de ce chapitre permettent de
la rendre configurable sans jamais la coder en dur pour de bon :

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:donation_mailer, :from) || "dons@association.org"
  layout "mailer"
end
```

`Rails.application.credentials.dig(:donation_mailer, :from)` lit la clé
ajoutée à l'exercice 7.2 ; `|| "dons@association.org"` garde une valeur
par défaut si l'environnement courant (développement, test) n'a rien
défini sous cette clé — la ligne `layout "mailer"` déjà présente n'est
pas retirée, elle n'a simplement aucune raison de changer ici.

## Exercices

**7.6 — Lire et annoter `config/deploy.yml`**

Ouvrez `config/deploy.yml` de `donor_crm`. Dans `NOTES.md` (partie 0),
pour chacune des sections `service`, `image`, `servers`, `proxy` et
`registry`, écrivez une phrase expliquant son rôle dans un déploiement.

**7.7 — Vérifier que .kamal/secrets ne contient aucune valeur en clair**

Créez ou complétez `.kamal/secrets` comme ci-dessus. Relisez chaque
ligne et vérifiez qu'aucune ne contient de valeur en clair — uniquement
des indirections (`$(cat ...)`, une variable d'environnement). Ce
fichier peut être commité sans risque ; dans `NOTES.md`, expliquez
pourquoi `config/master.key`, lui, ne le pourrait jamais.

**7.8 — Comprendre le rôle de Thruster devant Puma**

Ouvrez `bin/thrust` et le `Dockerfile` (chapitre précédent), et repérez
la ligne qui démarre le serveur en production. Dans `NOTES.md`, listez
deux responsabilités que Thruster ajoute par rapport à `bin/rails
server` seul.

**7.9 — Rendre l'expéditeur des emails configurable par environnement**

Ajoutez la clé `donation_mailer.from` aux credentials de production
(`RAILS_ENV=production bin/rails credentials:edit`), avec une adresse
différente de celle utilisée en développement. Modifiez
`ApplicationMailer` comme ci-dessus, sans retirer `layout "mailer"`.
Vérifiez en console que l'environnement de développement retombe bien
sur `"dons@association.org"`.

**7.10 — Rédiger la checklist de mise en production**

Dans `NOTES.md`, rédigez la checklist complète qu'une personne de
l'association devrait suivre avant un premier déploiement réel de
`donor_crm` : au minimum, `master.key` sauvegardé en lieu sûr,
`config/deploy.yml` renseigné avec un vrai serveur et un vrai domaine,
`.kamal/secrets` rempli, et `bin/rails assets:precompile` vérifié en
local (chapitre précédent). Relisez cette checklist à la lumière de
tout ce que ce cours a construit depuis la partie 0 : chaque ligne
doit correspondre à quelque chose que vous avez réellement fait tourner
au moins une fois.
