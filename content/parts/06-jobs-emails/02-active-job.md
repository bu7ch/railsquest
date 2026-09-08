---
title: "Active Job : traitement en arrière-plan"
exercises:
  - key: "6.6"
    title: "Comprendre l'adaptateur de file d'attente"
  - key: "6.7"
    title: "Créer GoalReachedNotifierJob et son mailer"
  - key: "6.8"
    title: "Déclencher le job depuis Donation sans perdre le broadcast existant"
  - key: "6.9"
    title: "Ajouter une politique de nouvelle tentative avec retry_on"
  - key: "6.10"
    title: "Tester le job et son déclenchement"
---

# Active Job : traitement en arrière-plan

`deliver_later` (chapitre précédent) ne fait pas exister une file
d'attente par magie : il enfile un job Active Job, exactement comme
celui que ce chapitre va écrire à la main. Un job encapsule un travail
qui peut attendre quelques secondes sans gêner personne — envoyer un
email, recalculer un total, prévenir une équipe — et le sort du cycle
requête/réponse.

## L'adaptateur de file d'attente

```ruby
# config/environments/production.rb
config.active_job.queue_adapter = :solid_queue
```

Rails 8 configure Solid Queue par défaut pour la production — une file
d'attente persistée dans la même base de données que le reste de
l'application, sans service externe à installer. En développement et en
test, l'adaptateur par défaut (`:async` en développement, `:test` en
test) exécute les jobs directement dans le même processus : pratique
pour itérer vite, sans jamais avoir besoin de démarrer un worker séparé
pendant qu'on écrit ses jobs.

## Un job qui compose avec ce qui existe déjà

Une campagne (partie 1) a un objectif, `goal_cents`. Quand un don la
fait atteindre cet objectif, l'équipe entière mérite d'être prévenue —
pas seulement le donateur qui vient de le déclencher.

```ruby
# app/mailers/campaign_mailer.rb
class CampaignMailer < ApplicationMailer
  def goal_reached(campaign, admin)
    @campaign = campaign

    mail to: admin.email_address, subject: "Objectif atteint : #{campaign.name}"
  end
end
```

`admin.email_address` est bien la colonne de `User` (partie 3) — un
`CampaignMailer` écrit à l'équipe, un `DonationMailer` écrit à un
donateur, deux destinataires différents, deux colonnes différentes.

```ruby
# app/jobs/goal_reached_notifier_job.rb
class GoalReachedNotifierJob < ApplicationJob
  queue_as :default

  def perform(campaign)
    User.admin.each do |admin|
      CampaignMailer.goal_reached(campaign, admin).deliver_now
    end
  end
end
```

`User.admin` réutilise le scope généré par `enum :role` en partie 3 —
exactement comme `Donor.recent` (partie 1) a été réutilisé tel quel par
la partie 2. `deliver_now` est correct ici : le job lui-même tourne déjà
en arrière-plan, il n'a pas besoin d'enfiler un second travail pour
faire le premier.

`ApplicationJob` est généré une fois pour toutes par `rails new`, comme
`ApplicationController` et `ApplicationMailer` : tout job en hérite.

## Déclencher le job sans effacer ce qui existe

`Donation` porte déjà un `after_create_commit` depuis la partie 5, pour
diffuser le don en direct. Un second callback s'ajoute à côté du
premier — il ne le remplace pas :

```ruby
# app/models/donation.rb
class Donation < ApplicationRecord
  belongs_to :donor
  belongs_to :campaign
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :donor_id, uniqueness: { scope: [ :campaign_id, :amount_cents ] }

  after_create_commit -> { broadcast_prepend_to campaign, target: "donations" }
  after_create_commit :notify_if_goal_reached

  private

  def notify_if_goal_reached
    GoalReachedNotifierJob.perform_later(campaign) if campaign.total_collected_cents >= campaign.goal_cents
  end
end
```

`campaign.total_collected_cents` (partie 1, exercice 1.7) calcule
`donations.sum(:amount_cents)` — ce chapitre ne le redéfinit pas, il le
consomme tel quel, comme la partie 2 a consommé `Donor.recent` sans le
réécrire. Deux `after_create_commit` sur le même modèle s'exécutent
tous les deux, dans l'ordre où ils sont déclarés : diffuser le don en
direct et vérifier l'objectif sont deux responsabilités distinctes,
chacune dans sa propre méthode plutôt que mélangées dans un seul bloc.

## Gérer un envoi qui échoue

Un serveur SMTP momentanément indisponible ne doit pas faire échouer
silencieusement toute la notification :

```ruby
class GoalReachedNotifierJob < ApplicationJob
  queue_as :default
  retry_on Net::SMTPServerBusy, wait: 5.seconds, attempts: 3

  def perform(campaign)
    User.admin.each do |admin|
      CampaignMailer.goal_reached(campaign, admin).deliver_now
    end
  end
end
```

`retry_on` relance automatiquement le job entier après le délai indiqué
si l'exception listée est levée, jusqu'à `attempts` tentatives — le
même geste que relancer une requête réseau qui a échoué une fois,
plutôt que d'abandonner la notification pour de bon.

## Exercices

**6.6 — Comprendre l'adaptateur de file d'attente**

Ouvrez `config/environments/production.rb`,
`config/environments/development.rb` et
`config/environments/test.rb` de votre `donor_crm`, et notez dans
`NOTES.md` (partie 0) l'adaptateur configuré dans chacun.

**6.7 — Créer `GoalReachedNotifierJob` et son mailer**

Créez `app/mailers/campaign_mailer.rb` et
`app/jobs/goal_reached_notifier_job.rb` comme ci-dessus. Depuis la
console, appelez `GoalReachedNotifierJob.perform_now(Campaign.first)`
et vérifiez dans les logs qu'un email est traité par admin existant.

**6.8 — Déclencher le job depuis `Donation` sans perdre le broadcast existant**

Ajoutez `after_create_commit :notify_if_goal_reached` et la méthode
privée `notify_if_goal_reached` à `Donation`, sans retirer le
`after_create_commit` de diffusion de la partie 5. Créez un don qui
atteint l'objectif d'une campagne et vérifiez que la diffusion en
direct fonctionne toujours en plus de l'envoi de la notification.

**6.9 — Ajouter une politique de nouvelle tentative avec `retry_on`**

Ajoutez `retry_on Net::SMTPServerBusy, wait: 5.seconds, attempts: 3` au
job. Expliquez dans `NOTES.md` pourquoi cette politique s'applique au
job entier (donc à tous les admins restants) plutôt qu'à un seul envoi
d'email.

**6.10 — Tester le job et son déclenchement**

Écrivez deux tests : un test de job (`ActiveJob::TestCase`) qui vérifie
que `GoalReachedNotifierJob.perform_now(campaign)` envoie bien un email
par admin (`assert_emails`) ; et un test de modèle qui vérifie
qu'atteindre l'objectif d'une campagne enfile bien le job
(`assert_enqueued_with(job: GoalReachedNotifierJob, args: [ campaign ])`
autour de la création du don qui l'atteint). Lancez toute la suite du
chapitre et vérifiez qu'elle passe.
