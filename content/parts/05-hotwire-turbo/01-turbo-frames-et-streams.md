---
title: "Turbo Frames et Turbo Streams : mises à jour en direct"
exercises:
  - key: "5.1"
    title: "Éditer un donateur en ligne avec un Turbo Frame"
  - key: "5.2"
    title: "Diffuser un nouveau don en direct avec broadcasts_to"
  - key: "5.3"
    title: "S'abonner au flux depuis la page d'une campagne"
  - key: "5.4"
    title: "Vérifier la mise à jour en direct avec deux onglets"
  - key: "5.5"
    title: "Diffuser la suppression d'un don"
---

# Turbo Frames et Turbo Streams : mises à jour en direct

Hotwire est l'approche par défaut de Rails 8 pour construire des
interfaces réactives sans écrire de JavaScript applicatif : Turbo gère la
navigation et les mises à jour partielles de page, Stimulus (chapitre
suivant) ajoute le comportement client là où c'est vraiment nécessaire.
Les deux sont déjà présents dans le Gemfile généré — rien à installer.

## Turbo Drive, déjà actif

Depuis le tout premier `rails new`, chaque clic sur un lien ou soumission
de formulaire est déjà intercepté par Turbo Drive : au lieu de recharger
la page entière, seul le `<body>` est remplacé, ce qui rend la navigation
plus rapide sans une seule ligne de code à écrire. C'est ce qui explique,
depuis la partie 2, pourquoi `redirect_to` semblait déjà instantané.

## Turbo Frame : mettre à jour un fragment de page

Un `<turbo-frame>` délimite une zone de page qui peut se rafraîchir
indépendamment du reste — utile pour éditer un donateur sans quitter sa
fiche :

```erb
<%# app/views/donors/show.html.erb %>
<turbo_frame_tag @donor do %>
  <p><%= @donor.name %> — <%= @donor.email %></p>
  <%= link_to "Modifier", edit_donor_path(@donor) %>
<% end %>
```

```erb
<%# app/views/donors/edit.html.erb %>
<turbo_frame_tag @donor do %>
  <%= render "form", donor: @donor %>
<% end %>
```

Quand le lien « Modifier » est cliqué, Turbo charge `edit.html.erb`, mais
n'insère dans la page que le contenu du `<turbo-frame>` dont l'`id`
correspond (`turbo_frame_tag @donor` génère le même id des deux côtés,
dérivé de la classe et de l'identifiant du donateur). Le reste de la page
— menu, mise en page — ne bouge pas.

## Turbo Stream : diffuser un changement à tous les visiteurs

Un Turbo Frame ne met à jour que la page de la personne qui a cliqué.
Pour propager un changement à **tous** les visiteurs connectés à une
page en temps réel — un tableau de bord de dons, par exemple — il faut
diffuser via **Action Cable**, déjà configuré par défaut (Solid Cable).

```ruby
# app/models/donation.rb
class Donation < ApplicationRecord
  belongs_to :donor
  belongs_to :campaign
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :donor_id, uniqueness: { scope: [ :campaign_id, :amount_cents ] }

  after_create_commit -> { broadcast_prepend_to campaign, target: "donations" }
end
```

`broadcast_prepend_to campaign` diffuse un fragment HTML sur un flux
nommé d'après la campagne, à insérer en tête de l'élément dont l'id est
`"donations"`. `after_create_commit` (plutôt que `after_create`) attend
que la transaction soit réellement validée avant de diffuser — diffuser
un don qui serait ensuite annulé par un rollback n'aurait aucun sens.

```erb
<%# app/views/donations/_donation.html.erb %>
<div id="<%= dom_id(donation) %>">
  <%= donation.donor.name %> — <%= number_to_currency(donation.amount_cents / 100.0) %>
</div>
```

Rails cherche automatiquement ce partial `_donation.html.erb` pour
rendre chaque `Donation` diffusée — la même convention de nommage que
partout ailleurs dans Rails.

## S'abonner au flux

Côté vue, `turbo_stream_from` ouvre la connexion Action Cable et écoute
le flux nommé :

```erb
<%# app/views/campaigns/show.html.erb %>
<%= turbo_stream_from @campaign %>

<div id="donations">
  <%= render @campaign.donations %>
</div>
```

Toute personne ayant cette page ouverte voit apparaître un nouveau don
sans recharger quoi que ce soit — la diffusion et l'abonnement utilisent
le même nom de flux, dérivé de `@campaign` des deux côtés.

## Exercices

**5.1 — Éditer un donateur en ligne avec un Turbo Frame**

Enveloppez la fiche et le formulaire d'édition d'un donateur dans un
`turbo_frame_tag @donor` comme ci-dessus. Vérifiez que cliquer sur
« Modifier » puis « Enregistrer » ne recharge jamais toute la page.

**5.2 — Diffuser un nouveau don en direct avec `broadcasts_to`**

Ajoutez le `after_create_commit` ci-dessus à `Donation`, ainsi que le
partial `_donation.html.erb`. Créez un don depuis la console et vérifiez
qu'aucune erreur n'est levée (même sans abonné pour l'instant).

**5.3 — S'abonner au flux depuis la page d'une campagne**

Ajoutez `turbo_stream_from @campaign` et le conteneur `id="donations"` à
`campaigns/show.html.erb`. Ouvrez la page dans un navigateur, créez un
don depuis `bin/rails console` (aucun formulaire n'existe encore — le
chapitre suivant en ajoute un), et observez son apparition sans
rechargement.

**5.4 — Vérifier la mise à jour en direct avec deux onglets**

Ouvrez la page d'une même campagne dans deux onglets côte à côte. Créez
un don depuis la console dans un terminal à côté et vérifiez qu'il
apparaît instantanément dans les deux onglets.

**5.5 — Diffuser la suppression d'un don**

Ajoutez `after_destroy_commit -> { broadcast_remove_to campaign }` à
`Donation`. Vérifiez que supprimer un don depuis un onglet le fait
disparaître en direct dans l'autre.
