---
title: "MVC et convention over configuration"
exercises:
  - key: "0.1"
    title: "Installer Rails et générer un projet vide"
  - key: "0.2"
    title: "Repérer les 3 dossiers de app/ et dire à quoi chacun sert"
  - key: "0.3"
    title: "Lister les routes avec bin/rails routes"
  - key: "0.4"
    title: "Ajouter une seconde page statique avec son propre contrôleur"
  - key: "0.5"
    title: "Repérer la convention singulier/pluriel entre fichier, classe et table"
---

# MVC et convention over configuration

Rails organise toute application autour du patron **MVC** — Modèle, Vue,
Contrôleur — et d'un principe directeur : *convention over configuration*.
Plutôt que de configurer explicitement où se trouve chaque chose, Rails
impose des emplacements et des noms par défaut. Un fichier au bon endroit,
avec le bon nom, est automatiquement pris en compte.

Dans ce cours, on construit progressivement un **CRM de dons pour une
association** : des donateurs (`Donor`), des campagnes de collecte
(`Campaign`) et des dons (`Donation`). Chaque partie ajoute une couche à
cette application.

## Les trois rôles

- **Modèle** — représente les données et les règles métier (`Donor`,
  `Campaign`, `Donation`). Un modèle Rails hérite d'`ActiveRecord::Base`
  et correspond à une table de la base de données.
- **Vue** — ce que l'utilisateur voit : un template `.html.erb` qui mélange
  HTML et Ruby.
- **Contrôleur** — reçoit une requête HTTP, orchestre modèle(s) et vue,
  renvoie une réponse.

## Convention over configuration en pratique

Trois exemples que vous croiserez tout de suite :

```ruby
# app/models/donor.rb
class Donor < ApplicationRecord
end
```

Rails déduit que la table s'appelle `donors` (pluriel, snake_case) sans
qu'on l'écrive nulle part.

```ruby
# app/controllers/donors_controller.rb
class DonorsController < ApplicationController
  def index
    @donors = Donor.all
  end
end
```

L'action `index` cherche automatiquement la vue
`app/views/donors/index.html.erb` — encore une fois, aucune configuration.

```ruby
# config/routes.rb
resources :donors
```

Une seule ligne génère les 7 routes REST habituelles (`index`, `show`,
`new`, `create`, `edit`, `update`, `destroy`).

## Installer Rails

```bash
gem install rails
rails new donor_crm --database=sqlite3
cd donor_crm
bin/rails server
```

`bin/rails server` démarre un serveur de développement sur
`http://localhost:3000`.

## Lister les routes

Avant même d'écrire un contrôleur, on peut toujours demander à Rails
quelles routes existent déjà dans l'application :

```bash
bin/rails routes
```

Chaque ligne affiche un nom de route, un verbe HTTP, un chemin, et le
contrôleur/action qui la traite. Sur un projet fraîchement généré, cette
commande n'affiche que la route technique `/up` (vérification de santé) —
elle s'enrichira au fil du cours à mesure qu'on ajoute des `resources` et
des `root` dans `config/routes.rb`. C'est le premier réflexe utile quand
on ne sait plus quelle URL mène à quelle action.

## Convention de nommage

Le nom d'un fichier, d'une classe et d'une table suit une règle stricte,
et c'est cette règle — pas une configuration — qui les relie entre eux :

| Élément | Forme | Exemple |
|---|---|---|
| Fichier modèle | singulier, snake_case | `app/models/donor.rb` |
| Classe modèle | singulier, CamelCase | `class Donor` |
| Table en base | pluriel, snake_case | `donors` |
| Fichier contrôleur | pluriel, snake_case | `app/controllers/donors_controller.rb` |
| Classe contrôleur | pluriel, CamelCase | `class DonorsController` |

Un modèle reste toujours singulier (un `Donor` est une personne), tandis
qu'un contrôleur reste toujours pluriel (`DonorsController` orchestre la
collection des donateurs). Rails utilise la gem `ActiveSupport::Inflector`
pour passer de l'un à l'autre — c'est elle qui sait que le pluriel de
`donor` est `donors`, ou que celui de `campaign` est `campaigns`.

## Exercices

**0.1 — Installer Rails et générer un projet vide**

Installez Rails, générez un projet nommé `donor_crm`, lancez-le et
vérifiez que la page d'accueil par défaut s'affiche dans votre navigateur.

**0.2 — Repérer les 3 dossiers de `app/`**

Ouvrez `app/models`, `app/views` et `app/controllers` dans le projet
généré. Pour chacun, écrivez une phrase expliquant à quoi il sert, dans un
fichier `NOTES.md` à la racine du projet.

**0.3 — Lister les routes avec `bin/rails routes`**

Dans `donor_crm`, lancez `bin/rails routes` et notez dans `NOTES.md` la
seule route qui apparaît sur un projet fraîchement généré, et ce à quoi
elle sert.

**0.4 — Ajouter une seconde page statique avec son propre contrôleur**

Générez un `AboutController` avec une action `index` affichant une courte
présentation de l'association, ajoutez la route correspondante dans
`config/routes.rb`, et vérifiez que `bin/rails routes` affiche
désormais cette nouvelle route en plus de celle de l'exercice précédent.

**0.5 — Repérer la convention singulier/pluriel**

Dans votre `AboutController`, notez si son nom est singulier ou pluriel,
et pourquoi (il ne représente pas une collection d'enregistrements comme
`DonorsController` le ferait pour des donateurs). Écrivez la règle dans
`NOTES.md` avec vos propres mots.
