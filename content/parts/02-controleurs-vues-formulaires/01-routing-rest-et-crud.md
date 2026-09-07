---
title: "Routing REST et CRUD complet"
exercises:
  - key: "2.1"
    title: "Générer le contrôleur Donors avec les 7 actions REST"
  - key: "2.2"
    title: "Ajouter la suppression d'un donateur"
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
