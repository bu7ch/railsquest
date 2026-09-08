---
title: "Associations entre modèles"
exercises:
  - key: "1.6"
    title: "Générer Campaign et Donation avec leurs associations"
  - key: "1.7"
    title: "Calculer le total collecté sur une campagne"
  - key: "1.8"
    title: "Lister les donateurs d'une campagne avec has_many :through"
  - key: "1.9"
    title: "Supprimer une campagne et ses dons avec dependent: :destroy"
  - key: "1.10"
    title: "Interdire un doublon de don identique"
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
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

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
`donor_id` ni `campaign_id` échouera à la validation. `has_many :donations`
s'ajoute aux validations de `Donor` du chapitre précédent — sans les
remplacer : une classe Ruby ne perd jamais ce qu'elle contenait déjà
parce qu'on lui ajoute une ligne.

## Naviguer les associations

```ruby
donor = Donor.first
donor.donations              # toutes les donations de ce donateur
donor.donations.sum(:amount_cents)

campaign = Campaign.first
campaign.donations.count
```

## Traverser une association intermédiaire

`Campaign` n'est reliée à `Donor` que par l'intermédiaire de
`Donation` — aucune colonne `donor_id` directe sur `Campaign`. Plutôt que
d'écrire une jointure à la main, `has_many :through` nomme ce chemin :

```ruby
# app/models/campaign.rb
class Campaign < ApplicationRecord
  has_many :donations
  has_many :donors, through: :donations
end
```

```ruby
campaign = Campaign.first
campaign.donors           # tous les donateurs distincts ayant donné à cette campagne
campaign.donors.count
```

Rails traduit `campaign.donors` en une jointure SQL entre `campaigns`,
`donations` et `donors` — la relation `through:` documente l'intention
(« les donateurs de cette campagne, via ses dons ») plutôt que de laisser
deviner pourquoi la jointure existe.

## Suppression en cascade

Supprimer une campagne qui a des dons associés pose une question :
que deviennent ces dons ? Sans instruction explicite, Rails laisse des
lignes orphelines (`campaign_id` pointant vers une campagne qui n'existe
plus) — presque toujours un bug.

```ruby
class Campaign < ApplicationRecord
  has_many :donations, dependent: :destroy
  has_many :donors, through: :donations
end
```

`dependent: :destroy` supprime chaque `Donation` associée avant de
supprimer la `Campaign` elle-même. L'alternative `dependent: :nullify`
mettrait plutôt `campaign_id` à `nil` sur les dons plutôt que de les
supprimer — un choix métier différent, à faire consciemment plutôt que
de laisser Rails décider par défaut.

## Empêcher un doublon exact

Une validation d'unicité peut porter sur plusieurs colonnes à la fois,
utile pour interdire une combinaison précise plutôt qu'une seule valeur :

```ruby
class Donation < ApplicationRecord
  belongs_to :donor
  belongs_to :campaign
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :donor_id, uniqueness: { scope: [ :campaign_id, :amount_cents ] }
end
```

`scope:` restreint la vérification d'unicité aux lignes qui partagent
les mêmes `campaign_id` et `amount_cents` — un même donateur peut donner
plusieurs fois à la même campagne, tant que le montant diffère à chaque
fois (utile pour éviter un double-clic accidentel sur le bouton
d'enregistrement d'un don).

## Exercices

**1.6 — Générer `Campaign` et `Donation` avec leurs associations**

Générez les deux modèles comme ci-dessus, migrez, puis déclarez
`has_many`/`belongs_to` sur les trois modèles. Depuis la console, créez une
campagne, un donateur, et un don qui les relie.

**1.7 — Calculer le total collecté sur une campagne**

Ajoutez une méthode d'instance `total_collected_cents` sur `Campaign` qui
retourne la somme de `amount_cents` de ses dons. Vérifiez le résultat
depuis la console avec plusieurs dons.

**1.8 — Lister les donateurs d'une campagne avec `has_many :through`**

Ajoutez `has_many :donors, through: :donations` à `Campaign`. Depuis la
console, créez deux dons de deux donateurs différents sur la même
campagne, puis vérifiez que `campaign.donors` renvoie bien les deux.

**1.9 — Supprimer une campagne et ses dons avec `dependent: :destroy`**

Ajoutez `dependent: :destroy` sur `has_many :donations` dans `Campaign`.
Depuis la console, supprimez une campagne ayant des dons et vérifiez
qu'ils ont bien disparu (`Donation.count` avant/après).

**1.10 — Interdire un doublon de don identique**

Ajoutez la validation `uniqueness: { scope: [...] }` ci-dessus. Depuis la
console, vérifiez que créer deux fois le même don (même donateur, même
campagne, même montant) échoue au second essai, mais qu'un montant
différent passe.
