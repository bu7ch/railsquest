---
title: "Routing REST et CRUD complet"
exercises:
  - key: "2.1"
    title: "Générer le contrôleur Donors avec les 7 actions REST"
  - key: "2.2"
    title: "Ajouter la suppression d'un donateur"
  - key: "2.3"
    title: "Ajouter des liens de navigation entre les pages"
  - key: "2.4"
    title: "Publier une page Campagnes en lecture seule avec only:"
  - key: "2.5"
    title: "Vérifier le comportement en cas d'échec de validation"
---

# Routing REST et CRUD complet

`resources :donors` dans `config/routes.rb` génère 7 routes correspondant
aux opérations CRUD (Create, Read, Update, Delete). Ce chapitre construit
l'interface complète de gestion des donateurs — le premier CRUD entier du
CRM — puis l'utilise pour donner à `only:` un cas d'usage réel plutôt
qu'un exemple jetable.

| Verbe HTTP | URL | Action | Usage |
|---|---|---|---|
| GET | `/donors` | `index` | Liste des donateurs |
| GET | `/donors/new` | `new` | Formulaire de création |
| POST | `/donors` | `create` | Traite la soumission |
| GET | `/donors/:id` | `show` | Fiche d'un donateur |
| GET | `/donors/:id/edit` | `edit` | Formulaire d'édition |
| PATCH | `/donors/:id` | `update` | Traite la modification |
| DELETE | `/donors/:id` | `destroy` | Supprime |

## Le contrôleur

```ruby
class DonorsController < ApplicationController
  def index
    @donors = Donor.all
  end

  def show
    @donor = Donor.find(params[:id])
  end

  def new
    @donor = Donor.new
  end

  def create
    @donor = Donor.new(donor_params)
    if @donor.save
      redirect_to @donor, notice: "Donateur créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @donor = Donor.find(params[:id])
  end

  def update
    @donor = Donor.find(params[:id])
    if @donor.update(donor_params)
      redirect_to @donor, notice: "Donateur mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def donor_params
    params.require(:donor).permit(:name, :email)
  end
end
```

`donor_params` illustre les **strong parameters** : Rails refuse par
défaut d'assigner en masse des attributs non explicitement autorisés,
pour éviter qu'un client malveillant n'écrive des colonnes non prévues.

## Relier les pages entre elles

Un contrôleur REST complet ne sert à rien si rien ne mène d'une page à
l'autre. `link_to` génère un lien HTML à partir d'un texte et d'une
route nommée :

```erb
<%# app/views/donors/index.html.erb %>
<ul>
  <% @donors.each do |donor| %>
    <li><%= link_to donor.name, donor %></li>
  <% end %>
</ul>
```

`link_to donor.name, donor` déduit `donor_path(donor)` automatiquement à
partir de l'objet passé en second argument — encore une déduction de
Rails plutôt qu'une URL écrite à la main.

## Une ressource qui n'a pas besoin des 7 actions

Le CRM a aussi besoin d'une page publique listant les campagnes en
cours, pour que l'association puisse la partager — mais sans formulaire
de création, sans édition, sans suppression : les campagnes, elles,
restent gérées depuis la console pour l'instant. `only:` limite
`resources` à ce qui existe réellement :

```ruby
# config/routes.rb
resources :campaigns, only: %i[index show]
```

```ruby
# app/controllers/campaigns_controller.rb
class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.all
  end

  def show
    @campaign = Campaign.find(params[:id])
  end
end
```

`bin/rails routes` n'affiche alors que deux routes pour `campaigns` — ni
`new`, ni `create`, ni `edit`, ni `update`, ni `destroy` n'existent, et
toute tentative d'y accéder renverra une erreur de routage plutôt que
d'atteindre un contrôleur qui n'a pas cette action. C'est un choix
durable, pas une restriction temporaire : cette page publique en lecture
seule reste telle quelle pour le reste du cours.

## Exercices

**2.1 — Générer le contrôleur `Donors` avec les 7 actions REST**

Dans `donor_crm`, ajoutez `resources :donors` aux routes, créez
`DonorsController` avec `index`, `show`, `new`, `create`, `edit`, `update`
comme ci-dessus, et les vues `index.html.erb`/`show.html.erb`
correspondantes (une simple liste et une fiche suffisent). Vérifiez que
créer un donateur via le formulaire fonctionne.

**2.2 — Ajouter la suppression d'un donateur**

Ajoutez l'action `destroy` au contrôleur et un bouton de suppression sur
la page `show`, avec `button_to "Supprimer", @donor, method: :delete`.

**2.3 — Ajouter des liens de navigation entre les pages**

Dans `index.html.erb`, remplacez le texte brut du nom par un `link_to`
vers la fiche du donateur. Sur la page `show`, ajoutez un lien retour
vers `index` et un lien vers `edit`.

**2.4 — Publier une page Campagnes en lecture seule avec `only:`**

Ajoutez `resources :campaigns, only: %i[index show]`, le contrôleur et
les deux vues correspondantes (une liste, une fiche). Lancez
`bin/rails routes` et vérifiez qu'aucune route de création, modification
ou suppression n'existe pour `campaigns`.

**2.5 — Vérifier le comportement en cas d'échec de validation**

En supposant `Donor` déjà validé (nom et email requis, partie
précédente), soumettez le formulaire de création sans remplir aucun
champ. Vérifiez que la page `new` se réaffiche (au lieu d'une
redirection) et que le code de statut HTTP renvoyé est bien 422
(outils de développement du navigateur, onglet réseau).
