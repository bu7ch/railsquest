---
title: "Stimulus : interactivité côté client"
exercises:
  - key: "5.6"
    title: "Créer un premier contrôleur Stimulus"
  - key: "5.7"
    title: "Ajouter un compteur de caractères sur un champ"
  - key: "5.8"
    title: "Afficher ou masquer un formulaire au clic"
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

## Afficher ou masquer un élément

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
<div data-controller="toggle">
  <button data-action="toggle#toggle">Ajouter un don manuellement</button>
  <div data-toggle-target="panel" hidden>
    <%= render "donations/form" %>
  </div>
</div>
```

`hidden` est un attribut HTML natif — Stimulus se contente de l'activer
et de le désactiver, sans réimplémenter un système d'affichage
personnalisé.

## Exercices

**5.6 — Créer un premier contrôleur Stimulus**

Générez le contrôleur `hello` ci-dessus (ou adaptez celui déjà présent
dans un projet Rails fraîchement généré) et vérifiez qu'un clic sur le
bouton affiche bien le message.

**5.7 — Ajouter un compteur de caractères sur un champ**

Ajoutez le contrôleur `character-count` sur le champ de message d'un
formulaire de don dans `donor_crm`. Vérifiez que le nombre affiché
augmente à chaque caractère tapé.

**5.8 — Afficher ou masquer un formulaire au clic**

Utilisez le contrôleur `toggle` ci-dessus pour masquer par défaut le
formulaire d'ajout manuel d'un don sur la page d'une campagne, et
l'afficher au clic sur un bouton.

**5.9 — Copier un lien de partage dans le presse-papiers**

Écrivez un contrôleur `clipboard` avec une action `copy` qui utilise
`navigator.clipboard.writeText(...)` pour copier l'URL publique d'une
campagne. Affichez un court message de confirmation après la copie.

**5.10 — Désactiver le bouton de soumission pendant l'envoi**

Écrivez un contrôleur `submit-once` qui désactive le bouton de
soumission d'un formulaire dès qu'il est cliqué (`data-action:
"submit->submit-once#disable"`), pour empêcher un double-clic
d'enregistrer deux fois le même don.
