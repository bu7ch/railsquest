---
title: "Anatomie d'une application générée"
exercises:
  - key: "0.6"
    title: "Observer le rechargement à chaud sur la page À propos"
  - key: "0.7"
    title: "Comparer le nom de PagesController à ses fichiers de vue"
  - key: "0.8"
    title: "Ajouter une page Mentions légales servie depuis public/"
  - key: "0.9"
    title: "Lire le Gemfile et repérer une dépendance"
  - key: "0.10"
    title: "Retracer le chemin complet d'une requête vers /about"
---

# Anatomie d'une application générée

`rails new` génère une arborescence complète. Vous avez déjà touché
`app/`, `config/routes.rb` et `Gemfile.lock` en construisant vos deux
premières pages ; ce chapitre revient sur ce qui les entoure — toujours
avec le même petit site comme fil conducteur.

- `app/` — le code de l'application (modèles, vues, contrôleurs, jobs,
  mailers...).
- `config/` — configuration, dont `config/routes.rb` qui définit les URLs
  de l'application.
- `db/` — les migrations et `db/schema.rb`, qui n'entrent en jeu qu'à
  partir de la partie suivante, une fois un premier modèle créé.
- `test/` — les tests automatisés, écrits avec Minitest par défaut.
- `public/` — des fichiers servis tels quels par le serveur, sans passer
  par un contrôleur ni une vue.

## Le rechargement à chaud

`bin/rails server` recharge automatiquement votre code à chaque requête
en développement — pas besoin de le redémarrer après avoir modifié un
contrôleur ou une vue. C'est ce qui rend l'aller-retour éditeur/navigateur
aussi rapide pendant tout ce cours.

## La convention de nommage, sur un cas réel

Le nom d'un fichier, d'une classe et d'une table suit une règle stricte :

| Élément | Forme | Exemple |
|---|---|---|
| Fichier contrôleur | snake_case | `app/controllers/pages_controller.rb` |
| Classe contrôleur | CamelCase | `class PagesController` |
| Dossier de vues | snake_case, dérivé du contrôleur | `app/views/pages/` |
| Fichier de vue | nom de l'action | `home.html.erb`, `about.html.erb` |

`PagesController` reste pluriel même s'il ne représente aucune collection
d'enregistrements — c'est la convention Rails pour tout contrôleur,
qu'il gère une ressource (`DonorsController`, dès la partie suivante) ou
simplement des pages (`PagesController`, ici). Le dossier de vues,
`app/views/pages/`, reprend le même nom que le contrôleur sans le
suffixe `Controller` : c'est cette correspondance de noms, et elle seule,
qui permet à Rails de retrouver `home.html.erb` sans configuration.

## `app/assets` et `public/`

Deux dossiers qui semblent proches mais ont un rôle différent :

- `app/assets/` — CSS, images, fonts destinés à être traités par Rails
  (Propshaft calcule un nom de fichier avec empreinte pour la mise en
  cache navigateur, par exemple).
- `public/` — fichiers servis tels quels, sans aucun traitement.

Un fichier posé dans `public/` est immédiatement accessible à l'URL
correspondant à son nom, sans route, sans contrôleur, sans vue :

```
public/mentions.html  →  http://localhost:3000/mentions.html
```

Aucune des trois couches MVC n'intervient ici — ni utile ni souhaitable
pour un contenu qui ne changera jamais.

## Le `Gemfile`

`Gemfile` liste les dépendances (les *gems*) du projet ; `Gemfile.lock`,
généré automatiquement, fige la version exacte de chacune pour que toute
l'équipe installe rigoureusement les mêmes versions. Sans la première
ligne ci-dessous, ni `rails new`, ni `bin/rails server`, ni les deux
pages construites dans ce chapitre n'existeraient :

```ruby
# Gemfile
gem "rails", "~> 8.0"
gem "sqlite3", ">= 2.1"
```

## Exercices

**0.6 — Observer le rechargement à chaud sur la page À propos**

Serveur toujours lancé, modifiez le texte de `about.html.erb`,
enregistrez, et rechargez la page dans le navigateur sans redémarrer
`bin/rails server`. Vérifiez que le nouveau texte apparaît immédiatement.

**0.7 — Comparer le nom de `PagesController` à ses fichiers de vue**

Dans `NOTES.md`, notez le nom du dossier de vues associé à
`PagesController`, et pourquoi ce nom précis (pas un autre) est celui que
Rails va chercher automatiquement pour chaque action.

**0.8 — Ajouter une page Mentions légales servie depuis `public/`**

Créez `public/mentions.html` avec un court texte, et vérifiez qu'elle est
accessible sans route ni contrôleur. Dans `NOTES.md`, notez une raison
pour laquelle la page À propos, elle, doit rester une vraie vue Rails
plutôt qu'un fichier `public/`.

**0.9 — Lire le `Gemfile` et repérer une dépendance**

Ouvrez le `Gemfile` de `donor_crm` et repérez la ligne qui déclare la
dépendance à Rails lui-même. Ouvrez ensuite `Gemfile.lock` et retrouvez
la version exacte résolue pour cette même gem.

**0.10 — Retracer le chemin complet d'une requête vers `/about`**

Dans `NOTES.md`, écrivez, dans l'ordre, les étapes traversées par une
requête `GET /about` depuis le navigateur jusqu'à la réponse HTML :
quel fichier de routes l'intercepte, quelle méthode de quel contrôleur
elle déclenche, et quel fichier de vue produit finalement la réponse.
