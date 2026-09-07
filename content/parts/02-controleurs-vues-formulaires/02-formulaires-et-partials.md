---
title: "Formulaires, partials et flash"
exercises:
  - key: "2.3"
    title: "Factoriser le formulaire de Donor en partial"
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

## Flash messages

`redirect_to @donor, notice: "Donateur créé."` stocke le message dans
`flash[:notice]`, disponible sur la prochaine requête seulement. Il faut
l'afficher dans le layout :

```erb
<%# app/views/layouts/application.html.erb, dans <body> %>
<% if notice %>
  <p class="flash-notice"><%= notice %></p>
<% end %>
```

## Exercices

**2.3 — Factoriser le formulaire de `Donor` en partial**

Dans `donor_crm`, extrayez le formulaire de `new.html.erb` dans un partial
`_form.html.erb` réutilisé par `new.html.erb` et `edit.html.erb`. Ajoutez
l'affichage du flash dans le layout et vérifiez qu'un message apparaît
après création et après modification.
