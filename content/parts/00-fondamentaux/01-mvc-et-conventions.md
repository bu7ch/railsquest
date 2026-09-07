---
title: "MVC et convention over configuration"
exercises:
  - key: "0.1"
    title: "Installer Rails et générer un projet vide"
  - key: "0.2"
    title: "Repérer les 3 dossiers de app/ et dire à quoi chacun sert"
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

## Exercices

**0.1 — Installer Rails et générer un projet vide**

Installez Rails, générez un projet nommé `donor_crm`, lancez-le et
vérifiez que la page d'accueil par défaut s'affiche dans votre navigateur.

**0.2 — Repérer les 3 dossiers de `app/`**

Ouvrez `app/models`, `app/views` et `app/controllers` dans le projet
généré. Pour chacun, écrivez une phrase expliquant à quoi il sert, dans un
fichier `NOTES.md` à la racine du projet.
