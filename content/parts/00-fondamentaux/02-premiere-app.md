---
title: "Anatomie d'une application générée"
exercises:
  - key: "0.6"
    title: "Modifier la page d'accueil par défaut"
  - key: "0.7"
    title: "Comparer les environnements development et test"
  - key: "0.8"
    title: "Lire db/schema.rb après une première migration"
  - key: "0.9"
    title: "Distinguer app/assets et public/"
  - key: "0.10"
    title: "Lire le Gemfile et repérer une dépendance"
---

# Anatomie d'une application générée

`rails new` génère une arborescence complète. Voici les dossiers que vous
utiliserez le plus dans ce cours :

- `app/` — le code de l'application (modèles, vues, contrôleurs, jobs,
  mailers...).
- `config/` — configuration, dont `config/routes.rb` qui définit les URLs
  de l'application.
- `db/` — les migrations (évolutions du schéma de base de données) et
  `db/schema.rb` (l'état courant du schéma).
- `test/` — les tests automatisés, écrits avec Minitest par défaut.

## `config/routes.rb`

C'est le point d'entrée de toute requête : Rails y cherche quelle
combinaison contrôleur/action doit traiter une URL donnée.

```ruby
Rails.application.routes.draw do
  root "pages#home"
end
```

Ici, une requête sur `/` est dirigée vers l'action `home` de
`PagesController`.

## Le serveur de développement

`bin/rails server` recharge automatiquement votre code à chaque requête en
développement — pas besoin de redémarrer le serveur après avoir modifié un
contrôleur ou une vue.

## Les environnements

Une même application Rails tourne dans plusieurs **environnements**, dont
la configuration diffère : `config/environments/development.rb`,
`test.rb` et `production.rb`. Le développement recharge le code à chaud et
affiche des erreurs détaillées ; les tests utilisent une base de données
séparée (pour ne jamais abîmer vos données de développement) ; la
production met en cache les assets et masque les détails d'erreur aux
visiteurs. `Rails.env` indique l'environnement courant à l'exécution.

## `db/schema.rb`

Après la première migration, `db/schema.rb` reflète l'état cumulé de
toutes les migrations exécutées — c'est le fichier à lire pour connaître
la structure actuelle de la base, jamais une migration individuelle prise
isolément (le sujet des migrations est développé en détail dans la partie
suivante).

## `app/assets` et `public/`

Deux dossiers qui semblent proches mais ont un rôle différent :

- `app/assets/` — CSS, images, fonts destinés à être traités par Rails
  (Propshaft calcule un nom de fichier avec empreinte pour la mise en
  cache navigateur, réécrit les URLs entre feuilles de style, etc.).
- `public/` — fichiers servis tels quels, sans aucun traitement :
  `public/robots.txt` ou une page d'erreur statique comme
  `public/404.html`, par exemple, arrivent au navigateur identiques à
  ce qu'ils sont sur disque.

## Le `Gemfile`

`Gemfile` liste les dépendances (les *gems*) du projet ; `Gemfile.lock`,
généré automatiquement, fige la version exacte de chacune — y compris
leurs propres dépendances — pour que toute l'équipe (et la production)
installe rigoureusement les mêmes versions.

```ruby
# Gemfile
gem "rails", "~> 8.0"
gem "sqlite3", ">= 2.1"
```

`bundle install` lit le `Gemfile`, résout les versions compatibles entre
elles, les installe, et écrit (ou met à jour) `Gemfile.lock`.

## Exercices

**0.6 — Modifier la page d'accueil par défaut**

Dans votre projet `donor_crm`, créez un contrôleur `PagesController` avec
une action `home`, une vue correspondante affichant "Bienvenue sur le CRM
de dons", et faites pointer `root` vers cette action dans
`config/routes.rb`. Vérifiez dans le navigateur.

**0.7 — Comparer les environnements `development` et `test`**

Ouvrez `config/environments/development.rb` et `config/environments/test.rb`
côte à côte. Notez dans `NOTES.md` deux différences de configuration que
vous y repérez.

**0.8 — Lire `db/schema.rb` après une première migration**

Générez n'importe quel modèle simple (par exemple
`bin/rails generate model Note content:text`), migrez, puis ouvrez
`db/schema.rb`. Repérez la table créée et notez la ligne qui enregistre
le numéro de la dernière migration appliquée.

**0.9 — Distinguer `app/assets` et `public/`**

Ajoutez un fichier `public/hello.txt` contenant du texte, et vérifiez
qu'il est accessible tel quel à `http://localhost:3000/hello.txt`. Notez
dans `NOTES.md` pourquoi ce mécanisme ne convient pas pour un fichier CSS
qu'on veut voir mis en cache intelligemment par le navigateur.

**0.10 — Lire le `Gemfile` et repérer une dépendance**

Ouvrez le `Gemfile` de `donor_crm` et repérez la ligne qui déclare la
dépendance à Rails lui-même. Ouvrez ensuite `Gemfile.lock` et retrouvez
la version exacte résolue pour cette même gem.
