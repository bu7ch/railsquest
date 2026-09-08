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
    title: "Restreindre les routes générées avec only:"
  - key: "2.5"
    title: "Vérifier le comportement en cas d'échec de validation"
---

# Routing REST et CRUD complet

`resources :donors` dans `config/routes.rb` génère 7 routes correspondant
aux opérations CRUD (Create, Read, Update, Delete) :

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

## Restreindre les routes générées

`resources :donors` génère les 7 routes par défaut, mais toutes ne sont
pas toujours utiles. `only:` (ou son inverse `except:`) limite la
génération à ce qui existe réellement :

```ruby
resources :donors, only: %i[index show new create edit update destroy]
```

Une ressource qui n'expose jamais de suppression, par exemple, peut
écrire `only: %i[index show new create edit update]` — `bin/rails routes`
n'affichera alors plus jamais de route `DELETE` pour cette ressource,
et toute tentative d'y accéder renverra une erreur de routage plutôt que
d'atteindre un contrôleur qui n'a pas cette action.

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

**2.4 — Restreindre les routes générées avec `only:`**

Si votre CRM n'expose pas encore de suppression accessible publiquement,
déclarez temporairement `resources :donors, only: %i[index show new
create edit update]`, lancez `bin/rails routes` et constatez que la route
`DELETE` a disparu. Remettez `resources :donors` sans restriction une
fois l'exercice terminé, puisque la partie suivante en aura besoin.

**2.5 — Vérifier le comportement en cas d'échec de validation**

En supposant `Donor` déjà validé (nom et email requis, partie
précédente), soumettez le formulaire de création sans remplir aucun
champ. Vérifiez que la page `new` se réaffiche (au lieu d'une
redirection) et que le code de statut HTTP renvoyé est bien 422
(outils de développement du navigateur, onglet réseau).
