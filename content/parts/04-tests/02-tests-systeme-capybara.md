---
title: "Tests système avec Capybara"
exercises:
  - key: "4.4"
    title: "Écrire un test système pour la création d'un donateur"
  - key: "4.5"
    title: "Vérifier le message flash après création"
  - key: "4.6"
    title: "Lancer la suite complète et lire un échec"
---

# Tests système avec Capybara

Les tests de modèle et de contrôleur vérifient le code ; un test
**système** vérifie l'expérience réelle : il pilote un vrai navigateur
(headless, sans fenêtre visible) et interagit avec la page comme le
ferait une personne — cliquer, remplir un champ, lire ce qui s'affiche.
Rails les fait tourner avec Capybara, déjà inclus dans le Gemfile généré.

## Anatomie d'un test système

```ruby
# test/system/donors_test.rb
require "application_system_test_case"

class DonorsTest < ApplicationSystemTestCase
  test "creating a donor from the browser" do
    visit new_donor_path

    fill_in "Nom", with: "Chloé"
    fill_in "Email", with: "chloe@example.org"
    click_on "Créer"

    assert_text "Chloé"
  end
end
```

`visit` charge une page réelle ; `fill_in "Nom", with:` cherche un champ
associé au label « Nom » et y tape le texte ; `click_on` clique un lien
ou un bouton par son texte visible. Capybara attend automatiquement
qu'un élément apparaisse avant d'agir dessus — pas besoin d'ajouter des
pauses artificielles pour laisser la page se charger.

```bash
PARALLEL_WORKERS=1 bin/rails test:system
```

Les tests système ouvrent un vrai navigateur par test ; les lancer en
parallèle peut saturer la machine, d'où l'intérêt de forcer un seul
worker pendant qu'on écrit et débogue les siens.

## Vérifier un message, pas seulement une redirection

Un test système peut vérifier ce qu'une personne verrait réellement à
l'écran après une action — texte, message flash, disparition d'un
élément — là où un test de contrôleur s'arrête au code de statut.

```ruby
test "shows a flash message after creating a donor" do
  visit new_donor_path

  fill_in "Nom", with: "Chloé"
  fill_in "Email", with: "chloe@example.org"
  click_on "Créer"

  assert_text "Donateur créé"
end
```

## Lire un échec de test système

Quand un test système échoue, Rails enregistre une capture d'écran dans
`tmp/screenshots/` au moment précis de l'échec — le réflexe est de
l'ouvrir avant de relire le code, elle montre souvent immédiatement ce
qui a réellement été rendu (un formulaire vide, une page d'erreur, un
label différent de celui attendu).

## Exercices

**4.4 — Écrire un test système pour la création d'un donateur**

Dans `test/system/donors_test.rb` de votre `donor_crm`, écrivez le test
ci-dessus adapté aux labels réels de votre formulaire. Lancez-le avec
`PARALLEL_WORKERS=1 bin/rails test:system`.

**4.5 — Vérifier le message flash après création**

Ajoutez une assertion sur le texte du message flash affiché après
création (adaptez le texte exact au message que renvoie votre action
`create`).

**4.6 — Lancer la suite complète et lire un échec**

Cassez temporairement un test (changez une assertion pour qu'elle
échoue exprès), lancez `bin/rails test`, lisez le message d'échec produit
par Minitest, puis rétablissez le test. Faites de même pour un test
système et ouvrez la capture d'écran générée dans `tmp/screenshots/`
avant de corriger.
