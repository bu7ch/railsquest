---
title: "Associations entre modèles"
exercises:
  - key: "1.3"
    title: "Générer Campaign et Donation avec leurs associations"
  - key: "1.4"
    title: "Calculer le total collecté sur une campagne"
---

# Associations entre modèles

Notre CRM a trois entités liées : un donateur fait des dons, chaque don
est rattaché à une campagne.

```bash
bin/rails generate model Campaign name:string goal_cents:integer
bin/rails generate model Donation amount_cents:integer donor:references campaign:references
bin/rails db:migrate
```

`donor:references` ajoute une colonne `donor_id` et un index, et génère
automatiquement `belongs_to :donor` dans `Donation`.

## Déclarer les associations

```ruby
# app/models/donor.rb
class Donor < ApplicationRecord
  has_many :donations
end
```

```ruby
# app/models/campaign.rb
class Campaign < ApplicationRecord
  has_many :donations
end
```

```ruby
# app/models/donation.rb
class Donation < ApplicationRecord
  belongs_to :donor
  belongs_to :campaign
  validates :amount_cents, numericality: { greater_than: 0 }
end
```

`belongs_to` est obligatoire par défaut dans Rails : une `Donation` sans
`donor_id` ni `campaign_id` échouera à la validation.

## Naviguer les associations

```ruby
donor = Donor.first
donor.donations              # toutes les donations de ce donateur
donor.donations.sum(:amount_cents)

campaign = Campaign.first
campaign.donations.count
```

## Exercices

**1.3 — Générer `Campaign` et `Donation` avec leurs associations**

Générez les deux modèles comme ci-dessus, migrez, puis déclarez
`has_many`/`belongs_to` sur les trois modèles. Depuis la console, créez une
campagne, un donateur, et un don qui les relie.

**1.4 — Calculer le total collecté sur une campagne**

Ajoutez une méthode d'instance `total_collected_cents` sur `Campaign` qui
retourne la somme de `amount_cents` de ses dons. Vérifiez le résultat
depuis la console avec plusieurs dons.
