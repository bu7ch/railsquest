---
title: "Tests système avec Capybara"
exercises:
  - key: "4.6"
    title: "Écrire un test système pour la création d'un donateur"
  - key: "4.7"
    title: "Vérifier le message flash après création"
  - key: "4.8"
    title: "Confirmer une suppression acceptée jusque dans le navigateur"
  - key: "4.9"
    title: "Vérifier un refus de suppression jusque dans le navigateur"
  - key: "4.10"
    title: "Casser volontairement un test et lire l'échec"
---

# Tests système avec Capybara

Les tests de modèle et de contrôleur (chapitre précédent) vérifient le
code depuis l'intérieur ; un test **système** vérifie l'expérience
réelle : il pilote un vrai navigateur (headless, sans fenêtre visible) et
interagit avec la page comme le ferait une personne — cliquer, remplir
un champ, lire ce qui s'affiche. Ce chapitre reprend le même donateur et
la même règle de suppression que le chapitre précédent, mais vus depuis
le navigateur plutôt que depuis le contrôleur.

## Anatomie d'un test système

```ruby
# test/system/donors_test.rb
require "application_system_test_case"

class DonorsTest < ApplicationSystemTestCase
  test "creating a donor from the browser" do
    sign_in_as(users(:staff))
    visit new_donor_path

    fill_in "Nom", with: "Chloé"
    fill_in "Email", with: "chloe@example.org"
    click_on "Créer"

    assert_text "Chloé"
  end
end
```

`sign_in_as` (partie 3, ajoutée à `ApplicationSystemTestCase`) se
connecte réellement avant toute autre chose — `DonorsController` exige
une session depuis la partie 3, un test système n'y échappe pas plus
qu'un visiteur. `visit` charge ensuite une page réelle ; `fill_in "Nom",
with:` cherche un champ associé au label « Nom » et y tape le texte ;
`click_on` clique un lien ou un bouton par son texte visible. Capybara
attend automatiquement qu'un élément apparaisse avant d'agir dessus —
pas besoin d'ajouter des pauses artificielles pour laisser la page se
charger.

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
  sign_in_as(users(:staff))
  visit new_donor_path

  fill_in "Nom", with: "Chloé"
  fill_in "Email", with: "chloe@example.org"
  click_on "Créer"

  assert_text "Donateur créé"
end
```

## Accepter une boîte de confirmation

`turbo_confirm` (partie 2) affiche une boîte de dialogue native avant
d'envoyer la suppression. Un test système doit explicitement l'accepter
avec `accept_confirm`, sinon Capybara considère qu'elle reste ouverte et
que le clic n'a jamais réellement abouti :

```ruby
test "deletes a donor with no donations after confirming" do
  users(:staff).admin!
  sign_in_as(users(:staff))
  donor = Donor.create!(name: "Chloé", email: "chloe@example.org")
  visit donor_path(donor)

  accept_confirm do
    click_on "Supprimer"
  end

  assert_no_selector "td", text: "Chloé"
end
```

`assert_no_selector`, symétrique d'`assert_selector`, vérifie qu'un
élément est absent — la preuve que la ligne a bien disparu, pas
seulement que la requête de suppression est partie.

## Vérifier un refus, jusque dans le navigateur

Le même geste — cliquer sur « Supprimer », accepter la confirmation —
donne un résultat différent si le donateur a des dons (partie 2). Un
test système peut vérifier les deux issues avec la même mécanique que le
test de contrôleur du chapitre précédent, mais en observant ce qu'une
personne verrait réellement :

```ruby
test "refuses to delete a donor with donations, with an explanation" do
  users(:staff).admin!
  sign_in_as(users(:staff))
  donor = Donor.create!(name: "Chloé", email: "chloe@example.org")
  campaign = Campaign.create!(name: "Collecte hiver", goal_cents: 100_000)
  donor.donations.create!(campaign: campaign, amount_cents: 2_000)

  visit donor_path(donor)

  accept_confirm do
    click_on "Supprimer"
  end

  assert_text "suppression impossible"
  assert_selector "td", text: "Chloé"
end
```

`assert_selector "td", text: "Chloé"` confirme que la ligne est toujours
là — le test échouerait si la règle de refus s'était rompue et avait
laissé passer la suppression.

## Exercices

**4.6 — Écrire un test système pour la création d'un donateur**

Ajoutez la méthode `sign_in_as` à `test/application_system_test_case.rb`
comme ci-dessus. Dans `test/system/donors_test.rb` de votre `donor_crm`,
écrivez le test ci-dessus adapté aux labels réels de votre formulaire.
Lancez-le avec `PARALLEL_WORKERS=1 bin/rails test:system`.

**4.7 — Vérifier le message flash après création**

Ajoutez une assertion sur le texte du message flash affiché après
création (adaptez le texte exact au message que renvoie votre action
`create`).

**4.8 — Confirmer une suppression acceptée jusque dans le navigateur**

Écrivez le test de suppression ci-dessus pour un donateur sans don :
basculez `users(:staff)` en admin, connectez-vous, `accept_confirm`
autour du clic, puis `assert_no_selector` pour vérifier sa disparition.

**4.9 — Vérifier un refus de suppression jusque dans le navigateur**

Écrivez le second test ci-dessus pour un donateur ayant un don associé :
vérifiez à la fois le message d'explication et la présence persistante
de la ligne du donateur.

**4.10 — Casser volontairement un test et lire l'échec**

Lancez `bin/rails test && PARALLEL_WORKERS=1 bin/rails test:system` :
toute la suite écrite dans cette partie doit passer. Modifiez ensuite
exprès l'assertion de l'exercice 4.9 pour qu'elle échoue (par exemple, en
attendant un texte qui n'apparaît jamais), relancez, et lisez le message
produit par Minitest ainsi que la capture d'écran générée dans
`tmp/screenshots/`. Rétablissez l'assertion correcte avant de continuer.
