---
title: "Autorisation par rôle : admin et collecteur de fonds"
exercises:
  - key: "3.6"
    title: "Ajouter un enum role à User (admin / fundraiser)"
  - key: "3.7"
    title: "Restreindre la suppression d'un donateur aux admins"
  - key: "3.8"
    title: "Masquer le bouton de suppression pour les non-admins"
  - key: "3.9"
    title: "Ajouter un test système vérifiant qu'un fundraiser ne peut pas supprimer"
  - key: "3.10"
    title: "Afficher le rôle de l'utilisateur connecté dans le layout"
---

# Autorisation par rôle : admin et collecteur de fonds

L'authentification répond à « qui êtes-vous ? ». L'**autorisation**
répond à une question différente : « qu'avez-vous le droit de faire, une
fois identifié ? ». Un collecteur de fonds (*fundraiser*) doit pouvoir
enregistrer des dons et consulter les donateurs, mais pas supprimer
définitivement un donateur — seul un administrateur le peut. Ce n'est pas
une question d'authentification (les deux sont bien connectés), mais de
règles métier propres à l'application.

## Ajouter un rôle

Rails permet de déclarer une colonne entière comme un ensemble de valeurs
nommées avec `enum`, plutôt que de comparer des chaînes de caractères un
peu partout dans le code.

```bash
bin/rails generate migration AddRoleToUsers role:integer
```

```ruby
class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, null: false, default: 0
  end
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { fundraiser: 0, admin: 1 }
end
```

`enum` génère automatiquement `user.admin?`, `user.fundraiser?`, et un
scope `User.admin`. La valeur par défaut (`0`, donc `fundraiser`) est
volontairement la moins privilégiée : un compte créé sans y penser ne
doit jamais hériter des droits d'administration par accident.

## Restreindre une action

L'autorisation se vérifie dans le contrôleur, avec un `before_action`
dédié — le même mécanisme que l'authentification, mais une question
différente :

```ruby
# app/controllers/donors_controller.rb
class DonorsController < ApplicationController
  before_action :require_admin, only: :destroy

  def destroy
    @donor = Donor.find(params[:id])
    if @donor.donations.any?
      redirect_to @donor, alert: "Ce donateur a des dons enregistrés : suppression impossible."
    else
      @donor.destroy
      redirect_to donors_path, notice: "Donateur supprimé."
    end
  end

  private

  def require_admin
    return if Current.user.admin?

    redirect_to donors_path, alert: "Réservé aux administrateurs."
  end
end
```

`Current.user` (fourni par le concern `Authentication` du chapitre
précédent) est déjà disponible ici : l'authentification a eu lieu avant
l'autorisation, dans l'ordre des `before_action`. Le corps de `destroy`
garde intacte la règle de la partie 2 (un donateur avec des dons ne se
supprime pas) : `before_action :require_admin` répond à « qui a le
droit d'essayer », le `if @donor.donations.any?` répond à « dans quel
état l'essai réussit » — deux questions différentes, deux emplacements
différents, jamais l'une à la place de l'autre.

## Adapter l'interface à ce qu'on a le droit de faire

Une action bloquée côté contrôleur doit aussi être invisible côté vue —
proposer un bouton qui échoue silencieusement est une mauvaise
expérience, pas une mesure de sécurité (la sécurité, elle, vient du
contrôleur).

```erb
<%# app/views/donors/show.html.erb %>
<% if Current.user.admin? %>
  <%= button_to "Supprimer", @donor, method: :delete %>
<% end %>
```

## Exercices

**3.6 — Ajouter un enum `role` à `User` (`admin` / `fundraiser`)**

Générez la migration, migrez, et déclarez `enum :role` comme ci-dessus.
Depuis la console, vérifiez qu'un utilisateur créé sans préciser de rôle
est bien `fundraiser?`, et qu'appeler `user.admin!` bascule son rôle.

**3.7 — Restreindre la suppression d'un donateur aux admins**

Ajoutez `before_action :require_admin, only: :destroy` à
`DonorsController`, sans retirer le `if @donor.donations.any?` de la
partie 2. Vérifiez manuellement, avec deux comptes (un admin, un
fundraiser), que seul l'admin peut tenter une suppression — et que même
lui se voit refuser la suppression d'un donateur qui a des dons.

**3.8 — Masquer le bouton de suppression pour les non-admins**

Dans `app/views/donors/show.html.erb`, entourez le bouton de suppression
d'un `if Current.user.admin?`. Vérifiez qu'un compte fundraiser ne voit
plus du tout le bouton.

**3.9 — Ajouter un test système vérifiant qu'un fundraiser ne peut pas supprimer**

Écrivez un test système (Capybara) qui se connecte avec un compte
fundraiser, visite la fiche d'un donateur, et vérifie que le bouton
« Supprimer » est absent de la page. Ajoutez un second test symétrique
pour un compte admin, qui vérifie sa présence.

**3.10 — Afficher le rôle de l'utilisateur connecté dans le layout**

Dans le layout de `donor_crm`, à côté du nom ou de l'email de
l'utilisateur connecté, affichez son rôle (« Admin » ou « Collecteur de
fonds ») pour que l'équipe sache toujours sous quel compte elle travaille.
