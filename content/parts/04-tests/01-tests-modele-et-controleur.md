---
title: "Tests de modèle et de contrôleur"
exercises:
  - key: "4.1"
    title: "Écrire un test de validation pour Donor"
  - key: "4.2"
    title: "Tester l'action index de DonorsController"
  - key: "4.3"
    title: "Tester les deux chemins de l'action create"
---

# Tests de modèle et de contrôleur

Rails installe Minitest par défaut — aucun gem à ajouter, aucune
configuration à écrire. `bin/rails generate model` et
`bin/rails generate controller` ont d'ailleurs déjà créé, à chaque fois,
un fichier de test vide à côté du code généré : Rails part du principe
que du code sans test n'est pas terminé.

## Tester un modèle

Un test de modèle vérifie les règles métier portées par le modèle :
validations, méthodes, associations — sans passer par une requête HTTP.

```ruby
# test/models/donor_test.rb
require "test_helper"

class DonorTest < ActiveSupport::TestCase
  test "requires a name" do
    donor = Donor.new(email: "a@example.org")

    assert_not donor.valid?
    assert_includes donor.errors[:name], "can't be blank"
  end

  test "is valid with a name and an email" do
    donor = Donor.new(name: "Alice", email: "alice@example.org")

    assert donor.valid?
  end
end
```

```bash
bin/rails test test/models/donor_test.rb
```

`assert donor.valid?` déclenche les validations sans sauvegarder ;
`donor.errors[:name]` liste les messages d'erreur associés à cet
attribut précis après un `valid?` qui a échoué.

## Tester un contrôleur

Un test de contrôleur (en réalité un test d'intégration léger dans
Rails moderne) simule une vraie requête HTTP et vérifie la réponse :
code de statut, redirection, contenu de la page.

```ruby
# test/controllers/donors_controller_test.rb
require "test_helper"

class DonorsControllerTest < ActionDispatch::IntegrationTest
  test "index lists donors" do
    Donor.create!(name: "Alice", email: "alice@example.org")

    get donors_path

    assert_response :success
    assert_select "body", /Alice/
  end
end
```

`get donors_path` envoie une vraie requête GET à travers le routeur, le
contrôleur et la vue — exactement comme un navigateur, mais sans
navigateur. `assert_select` cherche dans le HTML rendu, utile pour
vérifier qu'une donnée apparaît bien à l'écran plutôt que de supposer
qu'elle y est parce que la variable d'instance existe.

## Les deux chemins d'une action `create`

Une action qui peut réussir ou échouer mérite un test pour chaque
chemin — sinon la moitié de son comportement n'est jamais vérifiée.

```ruby
test "create succeeds with valid params" do
  assert_difference "Donor.count", 1 do
    post donors_path, params: { donor: { name: "Bob", email: "bob@example.org" } }
  end

  assert_redirected_to donor_path(Donor.last)
end

test "create fails with invalid params" do
  assert_no_difference "Donor.count" do
    post donors_path, params: { donor: { name: "" } }
  end

  assert_response :unprocessable_entity
end
```

`assert_difference`/`assert_no_difference` vérifient qu'un compteur a
bougé (ou non) autour d'un bloc — bien plus fiable que de recompter les
lignes d'une table à la main avant et après.

## Exercices

**4.1 — Écrire un test de validation pour `Donor`**

Dans `test/models/donor_test.rb`, écrivez un test qui vérifie qu'un
`Donor` sans email n'est pas valide, et un second qui vérifie qu'un
`Donor` avec un nom et un email l'est. Lancez-les avec
`bin/rails test test/models/donor_test.rb`.

**4.2 — Tester l'action `index` de `DonorsController`**

Créez deux donateurs depuis le test, appelez `get donors_path`, et
vérifiez que les deux noms apparaissent dans la réponse avec
`assert_select`.

**4.3 — Tester les deux chemins de l'action `create`**

Écrivez les deux tests ci-dessus (succès et échec) pour l'action
`create` de votre propre `DonorsController`. Lancez tout le fichier et
vérifiez que les deux passent.
