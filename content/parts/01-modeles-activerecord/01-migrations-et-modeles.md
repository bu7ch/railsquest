---
title: "Migrations et premiers modèles"
exercises:
  - key: "1.1"
    title: "Générer le modèle Donor avec une migration"
  - key: "1.2"
    title: "Ajouter des validations de présence sur Donor"
  - key: "1.3"
    title: "Rendre l'email de Donor unique"
  - key: "1.4"
    title: "Écrire un scope récents sur Donor"
  - key: "1.5"
    title: "Ajouter une colonne dans une nouvelle migration"
---

# Migrations et premiers modèles

Une **migration** décrit une évolution du schéma de base de données, sous
forme de code Ruby versionné. Rails applique les migrations dans l'ordre
et garde une trace de celles déjà exécutées.

## Générer un modèle

```bash
bin/rails generate model Donor name:string email:string
```

Cette commande crée trois fichiers : le modèle
`app/models/donor.rb`, une migration dans `db/migrate/`, et un fichier de
test `test/models/donor_test.rb`.

La migration générée ressemble à :

```ruby
class CreateDonors < ActiveRecord::Migration[8.0]
  def change
    create_table :donors do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
```

`t.timestamps` ajoute automatiquement `created_at` et `updated_at`,
maintenues par Rails.

```bash
bin/rails db:migrate
```

applique la migration et met à jour `db/schema.rb`.

## Validations

```ruby
class Donor < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true
end
```

`validates` empêche `save` de réussir si la condition n'est pas remplie —
`donor.save` renvoie alors `false` et `donor.errors` contient le détail.

## Validation d'unicité

Une validation de présence ne suffit pas à empêcher deux donateurs de
partager le même email — il faut une contrainte dédiée :

```ruby
class Donor < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
```

`uniqueness: true` interroge la base à chaque validation pour vérifier
qu'aucune autre ligne ne porte déjà cette valeur. Ce n'est qu'une
garantie applicative : deux requêtes simultanées peuvent encore passer
la validation avant que l'une des deux n'écrive — un index unique en
base (`add_index :donors, :email, unique: true`) est le complément qui
rend la contrainte réellement infranchissable.

## Interroger avec des scopes

Un **scope** nomme une requête réutilisable directement sur le modèle,
plutôt que de répéter la même clause `where` partout où elle sert :

```ruby
class Donor < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
end
```

```ruby
Donor.recent.first
Donor.recent.limit(5)
```

Un scope retourne toujours une relation ActiveRecord (pas un tableau),
ce qui permet de chaîner d'autres méthodes derrière (`limit`, `where`,
un autre scope) sans jamais charger la base tant qu'on n'a pas
effectivement besoin des résultats.

## La console Rails

```bash
bin/rails console
```

ouvre un IRB avec l'application chargée : idéal pour explorer les modèles
sans passer par le navigateur.

```ruby
Donor.create(name: "Alice", email: "alice@example.org")
Donor.count
Donor.first.name
```

## Ajouter une colonne après coup

Une migration déjà appliquée ne se modifie jamais — même pour corriger
une faute de frappe. Une base de données de production a déjà exécuté
son contenu ; la réécrire romprait l'historique partagé par toute
l'équipe. Le geste correct est toujours d'écrire une **nouvelle**
migration :

```bash
bin/rails generate migration AddPhoneToDonors phone:string
bin/rails db:migrate
```

```ruby
class AddPhoneToDonors < ActiveRecord::Migration[8.0]
  def change
    add_column :donors, :phone, :string
  end
end
```

`db/schema.rb` se met à jour automatiquement pour refléter l'état final
cumulé de toutes les migrations — c'est lui qu'on lit pour connaître la
structure actuelle de la base, jamais une migration individuelle prise
isolément.

## Exercices

**1.1 — Générer le modèle Donor avec une migration**

Dans `donor_crm`, générez un modèle `Donor` avec les champs `name:string`
et `email:string`, migrez la base, puis créez un donateur depuis la
console Rails.

**1.2 — Ajouter des validations de présence sur `Donor`**

Ajoutez des validations de présence sur `name` et `email`. Depuis la
console, vérifiez que `Donor.new.save` renvoie `false` et que
`Donor.new.errors.full_messages` liste les deux erreurs.

**1.3 — Rendre l'email de `Donor` unique**

Ajoutez `uniqueness: true` sur la validation d'email, puis un index
unique via une migration. Depuis la console, vérifiez que créer deux
donateurs avec le même email échoue au deuxième essai.

**1.4 — Écrire un scope `recent` sur `Donor`**

Ajoutez le scope `recent` ci-dessus. Créez trois donateurs à quelques
secondes d'intervalle depuis la console et vérifiez que
`Donor.recent.first` renvoie bien le dernier créé.

**1.5 — Ajouter une colonne dans une nouvelle migration**

Générez une migration qui ajoute une colonne `phone:string` à `donors`,
migrez, et vérifiez dans `db/schema.rb` que la colonne apparaît sur la
table `donors`.
