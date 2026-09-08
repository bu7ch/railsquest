---
title: "Envoyer un reçu par email avec Action Mailer"
exercises:
  - key: "6.1"
    title: "Générer DonationMailer avec une action receipt"
  - key: "6.2"
    title: "Personnaliser l'expéditeur par défaut"
  - key: "6.3"
    title: "Prévisualiser l'email sans l'envoyer"
  - key: "6.4"
    title: "Envoyer réellement le reçu à la création d'un don"
  - key: "6.5"
    title: "Tester le mailer"
---

# Envoyer un reçu par email avec Action Mailer

Un don enregistré (partie 5) mérite un accusé de réception : le
donateur doit savoir que son geste est bien arrivé, sans avoir à
retourner consulter le CRM. Action Mailer construit un email exactement
comme un contrôleur construit une page — une action, une vue, mais un
message plutôt qu'une réponse HTTP.

## Générer un mailer

```bash
bin/rails generate mailer DonationMailer receipt
```

Cette commande crée `app/mailers/donation_mailer.rb`, deux vues
(`app/views/donation_mailer/receipt.html.erb` et `receipt.text.erb` —
un email s'envoie dans les deux formats, pour les clients qui
n'affichent pas le HTML), et un fichier de test vide, exactement comme
`bin/rails generate controller` l'a fait pour chaque contrôleur depuis
la partie 2.

```ruby
# app/mailers/donation_mailer.rb
class DonationMailer < ApplicationMailer
  def receipt(donation)
    @donation = donation
    @donor = donation.donor
    @campaign = donation.campaign

    mail to: @donor.email, subject: "Merci pour votre don à #{@campaign.name}"
  end
end
```

`donation.donor` et `donation.campaign` réutilisent les associations
`belongs_to` déclarées en partie 1 — un mailer n'a rien de spécial vis-à-vis
du modèle, il navigue les mêmes associations que n'importe quel
contrôleur. `@donor.email` est bien la colonne `email` de `Donor`
(partie 1), à ne pas confondre avec `email_address` sur `User` (partie 3) :
deux modèles différents, deux colonnes différentes, jamais la même chose.

```erb
<%# app/views/donation_mailer/receipt.html.erb %>
<h1>Merci, <%= @donor.name %> !</h1>
<p>
  Nous avons bien reçu votre don de
  <%= number_to_currency(@donation.amount_cents / 100.0) %>
  pour la campagne « <%= @campaign.name %> ».
</p>
```

```erb
<%# app/views/donation_mailer/receipt.text.erb %>
Merci, <%= @donor.name %> !

Nous avons bien reçu votre don de <%= number_to_currency(@donation.amount_cents / 100.0) %>
pour la campagne « <%= @campaign.name %> ».
```

`number_to_currency` est le même helper de vue déjà utilisé dans le
partial `_donation.html.erb` de la partie 5 — les vues de mailer sont
des vues Rails ordinaires, avec les mêmes helpers.

## Un expéditeur par défaut

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "dons@association.org"
  layout "mailer"
end
```

`ApplicationMailer` est déjà généré par `rails new`, exactement comme
`ApplicationController` ; tout mailer en hérite, et `default from:`
s'applique à chacun sans avoir à le répéter dans `DonationMailer`.

## Prévisualiser sans envoyer

Envoyer un vrai email à chaque essai serait aussi peu pratique que
recharger toute la page à chaque clic (partie 5) l'aurait été sans
Turbo. Rails fournit un mécanisme de prévisualisation dédié :

```ruby
# test/mailers/previews/donation_mailer_preview.rb
class DonationMailerPreview < ActionMailer::Preview
  def receipt
    donor = Donor.first || Donor.create!(name: "Chloé", email: "chloe@example.org")
    campaign = Campaign.first || Campaign.create!(name: "Collecte hiver", goal_cents: 100_000)
    donation = donor.donations.first || donor.donations.create!(campaign: campaign, amount_cents: 2_000)

    DonationMailer.receipt(donation)
  end
end
```

Visitez `http://localhost:3000/rails/mailers/donation_mailer/receipt`
en développement pour voir le rendu HTML et texte du mail, sans qu'un
seul email ne soit réellement envoyé — `/rails/mailers` liste tous les
mailers prévisualisables de l'application, un peu comme `bin/rails
routes` liste toutes les routes.

## Envoyer pour de vrai

```ruby
# app/controllers/donations_controller.rb
class DonationsController < ApplicationController
  def create
    donor = Donor.find(params[:donor_id])
    donation = donor.donations.create!(donation_params)
    DonationMailer.receipt(donation).deliver_later

    redirect_to donor, notice: "Don enregistré."
  end

  private

  def donation_params
    params.require(:donation).permit(:campaign_id, :amount_cents, :message)
  end
end
```

`deliver_later` n'envoie rien immédiatement : il place le travail dans
une file d'attente, traitée en arrière-plan (chapitre suivant) — la
personne qui vient de soumettre le formulaire n'attend pas que l'email
parte réellement pour voir sa redirection. `deliver_now`, à l'inverse,
enverrait le mail en bloquant la requête en cours ; réservé aux cas où
l'envoi doit être synchrone, rares en pratique.

## Exercices

**6.1 — Générer `DonationMailer` avec une action `receipt`**

Générez le mailer comme ci-dessus. Complétez les deux vues avec le nom
du donateur, le montant du don, et le nom de la campagne.

**6.2 — Personnaliser l'expéditeur par défaut**

Ajoutez `default from: "dons@association.org"` (ou l'adresse de votre
choix) à `ApplicationMailer`. Vérifiez dans une console
(`DonationMailer.receipt(Donation.first).from`) que la valeur est bien
reprise.

**6.3 — Prévisualiser l'email sans l'envoyer**

Créez `DonationMailerPreview` comme ci-dessus et visitez
`/rails/mailers/donation_mailer/receipt` dans votre navigateur.
Vérifiez que les deux formats (HTML et texte) s'affichent correctement.

**6.4 — Envoyer réellement le reçu à la création d'un don**

Ajoutez `DonationMailer.receipt(donation).deliver_later` à l'action
`create` de `DonationsController`, comme ci-dessus. Créez un don depuis
le formulaire (partie 5) et vérifiez dans les logs du serveur
(`log/development.log`) qu'un email a été traité.

**6.5 — Tester le mailer**

Dans `test/mailers/donation_mailer_test.rb`, écrivez un test qui crée
un donateur, une campagne et un don, appelle
`DonationMailer.receipt(donation)`, et vérifie le destinataire
(`mail.to`), le sujet (`mail.subject`), et qu'un extrait attendu
apparaît dans `mail.body.encoded`.
