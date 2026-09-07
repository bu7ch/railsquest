---
title: "Migrations et premiers modèles"
exercises:
  - key: "1.1"
    title: "Générer le modèle Donor avec une migration"
  - key: "1.2"
    title: "Ajouter des validations de présence sur Donor"
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

## Exercices

**1.1 — Générer le modèle Donor avec une migration**

Dans `donor_crm`, générez un modèle `Donor` avec les champs `name:string`
et `email:string`, migrez la base, puis créez un donateur depuis la
console Rails.

**1.2 — Ajouter des validations de présence sur `Donor`**

Ajoutez des validations de présence sur `name` et `email`. Depuis la
console, vérifiez que `Donor.new.save` renvoie `false` et que
`Donor.new.errors.full_messages` liste les deux erreurs.
