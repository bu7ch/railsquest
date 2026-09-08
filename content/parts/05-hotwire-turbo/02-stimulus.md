---
title: "Stimulus : interactivité côté client"
exercises:
  - key: "5.6"
    title: "Créer un premier contrôleur Stimulus"
  - key: "5.7"
    title: "Ajouter un formulaire de don masqué par défaut sur la fiche d'un donateur"
  - key: "5.8"
    title: "Ajouter un compteur de caractères sur le champ message"
  - key: "5.9"
    title: "Copier un lien de partage dans le presse-papiers"
  - key: "5.10"
    title: "Désactiver le bouton de soumission pendant l'envoi"
---

# Stimulus : interactivité côté client

Turbo Streams diffuse des changements venus du serveur ; Stimulus gère le
comportement qui n'a besoin de rien d'autre que le navigateur — afficher
un compteur, copier du texte, désactiver un bouton. Un contrôleur
Stimulus est une petite classe JavaScript reliée au HTML par des
attributs `data-*`, jamais par du JavaScript qui va chercher des
éléments dans la page.

## Anatomie d'un contrôleur

```js
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  greet() {
    this.outputTarget.textContent = "Bonjour !"
  }
}
```

```erb
<div data-controller="hello">
  <button data-action="click->hello#greet">Cliquez ici</button>
  <span data-hello-target="output"></span>
</div>
```

`data-controller="hello"` active le contrôleur sur cet élément et ses
enfants ; `data-action="click->hello#greet"` relie l'événement `click` à
la méthode `greet` ; `data-hello-target="output"` rend l'élément
accessible depuis le contrôleur via `this.outputTarget`. Rails génère ce
premier fichier par défaut lors de l'installation de Stimulus — il sert
de modèle pour tous les suivants.

## Un formulaire pour enregistrer un don

Jusqu'ici, un don ne s'est jamais créé que depuis la console. Ajouter un
vrai formulaire suppose un contrôleur dédié — et, comme
`DonorsController`, protégé par défaut depuis la partie 3 : la saisie
d'un don reste un geste du personnel, jamais d'un visiteur de la page
publique d'une campagne (partie 2).

```ruby
# config/routes.rb
resources :donors do
  resources :donations, only: :create
end
```

```ruby
# app/controllers/donations_controller.rb
class DonationsController < ApplicationController
  def create
    donor = Donor.find(params[:donor_id])
    donor.donations.create!(donation_params)
    redirect_to donor, notice: "Don enregistré."
  end

  private

  def donation_params
    params.require(:donation).permit(:campaign_id, :amount_cents, :message)
  end
end
```

```erb
<%# app/views/donations/_form.html.erb %>
<%= form_with model: [ donor, Donation.new ] do |f| %>
  <%= f.collection_select :campaign_id, Campaign.all, :id, :name %>
  <%= f.label :amount_cents, "Montant (en centimes)" %>
  <%= f.number_field :amount_cents %>
  <%= f.label :message %>
  <%= f.text_area :message %>
  <%= f.submit "Enregistrer le don" %>
<% end %>
```

`DonationsController` n'a rien déclaré de particulier : il hérite du
même comportement par défaut que `DonorsController` depuis la partie 3,
sans avoir besoin d'un `allow_unauthenticated_access` que
`CampaignsController`, lui, a dû demander explicitement.

## Afficher ou masquer un élément

Ce formulaire n'a pas besoin d'être visible en permanence sur la fiche
d'un donateur — un bouton qui le révèle à la demande garde la page
lisible par défaut :

```js
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.hidden = !this.panelTarget.hidden
  }
}
```

```erb
<%# app/views/donors/show.html.erb %>
<div data-controller="toggle">
  <button data-action="toggle#toggle">Enregistrer un don</button>
  <div data-toggle-target="panel" hidden>
    <%= render "donations/form", donor: @donor %>
  </div>
</div>
```

`hidden` est un attribut HTML natif — Stimulus se contente de l'activer
et de le désactiver, sans réimplémenter un système d'affichage
personnalisé.

## Compter des caractères

```js
// app/javascript/controllers/character_count_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]

  update() {
    this.countTarget.textContent = this.inputTarget.value.length
  }
}
```

```erb
<%# app/views/donations/_form.html.erb, sur le champ message %>
<div data-controller="character-count">
  <%= f.text_area :message, data: {
        character_count_target: "input",
        action: "input->character-count#update"
      } %>
  <span data-character-count-target="count">0</span> caractères
</div>
```

`action: "input->character-count#update"` déclenche `update` à chaque
frappe (l'événement `input`, pas seulement `click`) — le compteur se met
à jour en temps réel sans jamais recharger quoi que ce soit côté serveur.

## Exercices

**5.6 — Créer un premier contrôleur Stimulus**

Générez le contrôleur `hello` ci-dessus (ou adaptez celui déjà présent
dans un projet Rails fraîchement généré) et vérifiez qu'un clic sur le
bouton affiche bien le message.

**5.7 — Ajouter un formulaire de don masqué par défaut sur la fiche d'un donateur**

Ajoutez `DonationsController`, la route imbriquée, et le partial
`_form.html.erb` ci-dessus à `donor_crm`. Enveloppez-le dans le
contrôleur Stimulus `toggle` sur `donors/show.html.erb`, masqué par
défaut, affiché au clic sur « Enregistrer un don ». Vérifiez qu'un don
créé depuis ce formulaire apparaît bien pour le donateur.

**5.8 — Ajouter un compteur de caractères sur le champ message**

Ajoutez le contrôleur `character-count` autour du champ `message` du
formulaire de l'exercice précédent. Vérifiez que le nombre affiché
augmente à chaque caractère tapé.

**5.9 — Copier un lien de partage dans le presse-papiers**

Écrivez un contrôleur `clipboard` avec une action `copy` qui utilise
`navigator.clipboard.writeText(...)` pour copier l'URL publique d'une
campagne, depuis sa page (partie 2 — accessible sans connexion). Affichez
un court message de confirmation après la copie.

**5.10 — Désactiver le bouton de soumission pendant l'envoi**

Écrivez un contrôleur `submit-once` qui désactive le bouton de
soumission dès qu'il est cliqué (`data-action:
"submit->submit-once#disable"`), et appliquez-le au formulaire de don de
l'exercice 5.7, pour empêcher un double-clic d'enregistrer deux fois le
même don.
