---
title: "Tests système avec Capybara"
exercises:
  - key: "4.6"
    title: "Écrire un test système pour la création d'un donateur"
  - key: "4.7"
    title: "Vérifier le message flash après création"
  - key: "4.8"
    title: "Lancer la suite complète et lire un échec"
  - key: "4.9"
    title: "Tester la redirection d'un visiteur non connecté"
  - key: "4.10"
    title: "Vérifier la disparition d'un élément avec assert_no_selector"
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

## Tester une redirection

L'authentification (partie 3) redirige un visiteur non connecté vers la
page de connexion. Un test système peut vérifier ce comportement de bout
en bout, sans jamais atteindre la page qu'il protège :

```ruby
test "redirects an unauthenticated visitor to the login page" do
  visit donors_path

  assert_current_path new_session_path
end
```

`assert_current_path` compare l'URL réellement affichée par le navigateur
à celle attendue — ici, la preuve que la redirection a bien eu lieu,
plutôt que de supposer son fonctionnement parce que le code semble
correct à la lecture.

## Vérifier qu'un élément a disparu

`assert_text`/`assert_selector` vérifient qu'un élément est présent ;
leur symétrique `assert_no_selector` vérifie son absence — utile pour
confirmer qu'une action a bien retiré quelque chose de la page.

```ruby
test "removes the donor row after deletion" do
  donor = Donor.create!(name: "Chloé", email: "chloe@example.org")
  visit donor_path(donor)

  click_on "Supprimer"

  assert_no_selector "td", text: "Chloé"
end
```

## Exercices

**4.6 — Écrire un test système pour la création d'un donateur**

Dans `test/system/donors_test.rb` de votre `donor_crm`, écrivez le test
ci-dessus adapté aux labels réels de votre formulaire. Lancez-le avec
`PARALLEL_WORKERS=1 bin/rails test:system`.

**4.7 — Vérifier le message flash après création**

Ajoutez une assertion sur le texte du message flash affiché après
création (adaptez le texte exact au message que renvoie votre action
`create`).

**4.8 — Lancer la suite complète et lire un échec**

Cassez temporairement un test (changez une assertion pour qu'elle
échoue exprès), lancez `bin/rails test`, lisez le message d'échec produit
par Minitest, puis rétablissez le test. Faites de même pour un test
système et ouvrez la capture d'écran générée dans `tmp/screenshots/`
avant de corriger.

**4.9 — Tester la redirection d'un visiteur non connecté**

En supposant l'authentification de la partie 3 déjà en place, écrivez un
test système qui visite `/donors` sans être connecté et vérifie, avec
`assert_current_path`, l'arrivée sur la page de connexion.

**4.10 — Vérifier la disparition d'un élément avec `assert_no_selector`**

Écrivez un test système qui crée un donateur, visite sa fiche, clique sur
« Supprimer », et vérifie avec `assert_no_selector` que son nom
n'apparaît plus dans la liste des donateurs.
