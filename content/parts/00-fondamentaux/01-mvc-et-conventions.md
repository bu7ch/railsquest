---
title: "MVC et convention over configuration"
exercises:
  - key: "0.1"
    title: "Installer Rails et générer un projet vide"
  - key: "0.2"
    title: "Repérer les 3 dossiers de app/ et dire à quoi chacun sert"
  - key: "0.3"
    title: "Remplacer la page d'accueil par défaut"
  - key: "0.4"
    title: "Lister les routes et repérer celle de l'accueil"
  - key: "0.5"
    title: "Ajouter une page À propos reliée à l'accueil"
---

# MVC et convention over configuration

Rails organise toute application autour du patron **MVC** — Modèle, Vue,
Contrôleur — et d'un principe directeur : *convention over configuration*.
Plutôt que de configurer explicitement où se trouve chaque chose, Rails
impose des emplacements et des noms par défaut. Un fichier au bon endroit,
avec le bon nom, est automatiquement pris en compte.

Dans ce cours, on construit progressivement un **CRM de dons pour une
association** : des donateurs (`Donor`), des campagnes de collecte
(`Campaign`) et des dons (`Donation`). Cette partie pose les bases avec un
tout petit projet — deux pages, sans base de données — avant que la
partie suivante n'y ajoute de vraies données.

## Les trois rôles

- **Modèle** — représente les données et les règles métier (`Donor`,
  `Campaign`, `Donation`). Un modèle Rails hérite d'`ApplicationRecord`
  (elle-même une sous-classe d'`ActiveRecord::Base`, générée une fois
  pour toutes par `rails new`) et correspond à une table de la base de
  données.
- **Vue** — ce que l'utilisateur voit : un template `.html.erb` qui mélange
  HTML et Ruby.
- **Contrôleur** — reçoit une requête HTTP, orchestre modèle(s) et vue,
  renvoie une réponse.

## Convention over configuration en pratique

Trois exemples que vous croiserez tout de suite (à partir de la partie
suivante, une fois `Donor` créé) :

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

## Remplacer la page d'accueil

La page par défaut de Rails n'est qu'un gabarit de bienvenue. La
remplacer par une vraie page demande les trois rôles à la fois : une
route, un contrôleur, une vue.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"
end
```

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
  end
end
```

```erb
<%# app/views/pages/home.html.erb %>
<h1>Bienvenue sur le CRM de dons</h1>
```

`root "pages#home"` dirige toute requête sur `/` vers l'action `home` du
contrôleur `PagesController` — aucune action n'a besoin de charger de
donnée pour l'instant, la méthode `home` peut rester vide, la vue suffit.

## Lister les routes

Maintenant qu'une vraie route existe, `bin/rails routes` devient
réellement utile :

```bash
bin/rails routes
```

La sortie affiche désormais `root GET / pages#home` en plus de la route
technique `/up` — le nom de la route (`root`), le verbe HTTP, le chemin,
et le contrôleur/action qui la traite. C'est le premier réflexe utile
quand on ne sait plus quelle URL mène à quelle action ; il ne fera que
s'enrichir au fil du cours.

## Ajouter une deuxième page

Une deuxième page suit exactement le même schéma — route, contrôleur,
vue — et permet de relier les deux avec `link_to` :

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"
  get "about", to: "pages#about"
end
```

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
  end

  def about
  end
end
```

```erb
<%# app/views/pages/home.html.erb %>
<h1>Bienvenue sur le CRM de dons</h1>
<%= link_to "À propos de l'association", about_path %>
```

`get "about", to: "pages#about"` nomme la route `about` par déduction du
chemin, ce qui donne automatiquement le helper `about_path` utilisable
dans `link_to` — la même mécanique de déduction que `root_path` pour la
route `root`.

## Exercices

**0.1 — Installer Rails et générer un projet vide**

Installez Rails, générez un projet nommé `donor_crm`, lancez-le et
vérifiez que la page d'accueil par défaut s'affiche dans votre navigateur.

**0.2 — Repérer les 3 dossiers de `app/`**

Ouvrez `app/models`, `app/views` et `app/controllers` dans le projet
généré. Pour chacun, écrivez une phrase expliquant à quoi il sert, dans un
fichier `NOTES.md` à la racine du projet.

**0.3 — Remplacer la page d'accueil par défaut**

Créez `PagesController` avec une action `home` et la vue correspondante
affichant « Bienvenue sur le CRM de dons », et faites pointer `root` vers
cette action. Vérifiez dans le navigateur.

**0.4 — Lister les routes et repérer celle de l'accueil**

Lancez `bin/rails routes` et notez dans `NOTES.md` la ligne qui
correspond à la page que vous venez de créer, en identifiant son nom de
route, son verbe HTTP et son action.

**0.5 — Ajouter une page « À propos » reliée à l'accueil**

Ajoutez l'action `about` et sa vue comme ci-dessus, avec une courte
présentation de l'association. Ajoutez le lien depuis la page d'accueil
avec `link_to` et `about_path`. Vérifiez que `bin/rails routes` affiche
bien les deux routes désormais.
