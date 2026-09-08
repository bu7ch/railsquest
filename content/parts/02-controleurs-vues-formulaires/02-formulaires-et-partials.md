---
title: "Formulaires, partials et flash"
exercises:
  - key: "2.6"
    title: "Factoriser le formulaire de Donor en partial"
  - key: "2.7"
    title: "Ajouter un champ supplémentaire au formulaire"
  - key: "2.8"
    title: "Afficher les erreurs de validation dans le formulaire"
  - key: "2.9"
    title: "Refuser la suppression d'un donateur ayant des dons"
  - key: "2.10"
    title: "Confirmer une suppression avec turbo_confirm"
---

# Formulaires, partials et flash

## `form_with`

```erb
<%= form_with model: @donor do |f| %>
  <%= f.label :name %>
  <%= f.text_field :name %>

  <%= f.label :email %>
  <%= f.email_field :email %>

  <%= f.submit %>
<% end %>
```

`form_with model: @donor` déduit automatiquement l'URL et la méthode HTTP
(POST vers `/donors` si `@donor` est nouveau, PATCH vers `/donors/:id`
sinon) — encore *convention over configuration*.

## Partials

`new.html.erb` et `edit.html.erb` ont presque toujours le même contenu :
le formulaire. On factorise avec un partial `_form.html.erb` :

```erb
<%# app/views/donors/_form.html.erb %>
<%= form_with model: donor do |f| %>
  <%= f.label :name %>
  <%= f.text_field :name %>

  <%= f.label :email %>
  <%= f.email_field :email %>

  <%= f.submit %>
<% end %>
```

```erb
<%# app/views/donors/new.html.erb %>
<h1>Nouveau donateur</h1>
<%= render "form", donor: @donor %>
```

```erb
<%# app/views/donors/edit.html.erb %>
<h1>Modifier le donateur</h1>
<%= render "form", donor: @donor %>
```

## Afficher les erreurs de validation

Quand `@donor.save` échoue, `@donor.errors` contient le détail des
validations non satisfaites — encore faut-il l'afficher dans le
formulaire plutôt que de laisser l'utilisateur deviner ce qui cloche :

```erb
<%# app/views/donors/_form.html.erb %>
<% if donor.errors.any? %>
  <ul class="form-errors">
    <% donor.errors.full_messages.each do |message| %>
      <li><%= message %></li>
    <% end %>
  </ul>
<% end %>

<%= form_with model: donor do |f| %>
  <%= f.label :name %>
  <%= f.text_field :name %>
  ...
```

`errors.full_messages` traduit chaque erreur en une phrase lisible
(« Name can't be blank ») plutôt qu'en paires attribut/type d'erreur
brutes.

## Flash messages

`redirect_to @donor, notice: "Donateur créé."` stocke le message dans
`flash[:notice]`, disponible sur la prochaine requête seulement. Il faut
l'afficher dans le layout :

```erb
<%# app/views/layouts/application.html.erb, dans <body> %>
<% if notice %>
  <p class="flash-notice"><%= notice %></p>
<% end %>
<% if alert %>
  <p class="flash-alert"><%= alert %></p>
<% end %>
```

`notice` et `alert` sont deux clés de `flash` traitées différemment par
convention : la première pour une confirmation, la seconde pour un
avertissement ou une erreur — deux couleurs, deux tons, jamais confondus
dans l'interface.

## Refuser une suppression

La suppression ajoutée au chapitre précédent (`destroy`) fonctionne pour
n'importe quel donateur — y compris un donateur qui a déjà des dons
enregistrés (partie 1), ce qui laisserait des `Donation` orphelines.
`alert` sert exactement ce cas : un refus, expliqué, plutôt qu'une
suppression silencieuse ou un plantage.

```ruby
# app/controllers/donors_controller.rb
def destroy
  @donor = Donor.find(params[:id])
  if @donor.donations.any?
    redirect_to @donor, alert: "Ce donateur a des dons enregistrés : suppression impossible."
  else
    @donor.destroy
    redirect_to donors_path, notice: "Donateur supprimé."
  end
end
```

`@donor.donations.any?` réutilise l'association `has_many :donations`
déclarée en partie 1 — le contrôleur consulte une règle métier qui vit
sur le modèle, il ne la réimplémente pas.

## Confirmer une action destructive

Une suppression est irréversible : un clic malheureux ne doit pas
suffire à déclencher.

```erb
<%= button_to "Supprimer", @donor, method: :delete,
      data: { turbo_confirm: "Confirmer la suppression de ce donateur ?" } %>
```

`turbo_confirm` affiche une boîte de dialogue native du navigateur ;
la requête `DELETE` n'est envoyée que si l'utilisateur confirme.

## Exercices

**2.6 — Factoriser le formulaire de `Donor` en partial**

Dans `donor_crm`, extrayez le formulaire de `new.html.erb` dans un partial
`_form.html.erb` réutilisé par `new.html.erb` et `edit.html.erb`. Ajoutez
l'affichage du flash dans le layout et vérifiez qu'un message apparaît
après création et après modification.

**2.7 — Ajouter un champ supplémentaire au formulaire**

Ajoutez un champ `phone` au formulaire (`f.telephone_field :phone`),
autorisez-le dans `donor_params`, et vérifiez qu'il est bien enregistré.

**2.8 — Afficher les erreurs de validation dans le formulaire**

Ajoutez le bloc d'erreurs ci-dessus en tête de `_form.html.erb`.
Soumettez le formulaire sans nom et vérifiez que le message d'erreur
s'affiche bien au-dessus des champs.

**2.9 — Refuser la suppression d'un donateur ayant des dons**

Modifiez `destroy` comme ci-dessus. Créez un donateur, associez-lui un
don depuis la console (partie 1), puis tentez de le supprimer depuis
l'interface : vérifiez que la suppression est refusée avec le message
d'alerte. Vérifiez ensuite qu'un donateur sans don se supprime
normalement, avec le `notice` habituel.

**2.10 — Confirmer une suppression avec `turbo_confirm`**

Ajoutez `data: { turbo_confirm: "..." }` au bouton de suppression de la
page `show`, pour qu'une suppression réellement acceptée par l'exercice
précédent demande encore une confirmation avant de partir. Vérifiez
qu'annuler la boîte de dialogue n'envoie aucune requête (onglet réseau
des outils de développement).
