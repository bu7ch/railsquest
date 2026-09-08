---
title: "Authentification avec le générateur Rails 8"
exercises:
  - key: "3.1"
    title: "Lancer le générateur d'authentification et migrer la base"
  - key: "3.2"
    title: "Créer un premier compte staff depuis la console"
  - key: "3.3"
    title: "Se connecter et se déconnecter depuis le navigateur"
  - key: "3.4"
    title: "Protéger DonorsController avec require_authentication"
  - key: "3.5"
    title: "Personnaliser le message de redirection pour un visiteur non connecté"
---

# Authentification avec le générateur Rails 8

Jusqu'ici, n'importe qui pouvait ouvrir `donor_crm` et voir, créer ou
supprimer des donateurs. Une association qui gère de vraies données de dons
a besoin d'un minimum de contrôle : seul le personnel autorisé doit pouvoir
toucher au CRM. Rails 8 fournit pour cela un générateur d'authentification
complet — pas un gem tiers, du code Ruby ordinaire que vous possédez et
pouvez modifier.

Ceci est distinct de la connexion GitHub de RailsQuest elle-même : ici,
on ajoute une authentification *à l'intérieur* de `donor_crm`, pour son
propre personnel (collecteurs de fonds, administrateurs), pas pour les
visiteurs du cours.

## Ce que génère `bin/rails generate authentication`

```bash
bin/rails generate authentication
bin/rails db:migrate
```

Cette commande crée plusieurs fichiers, tous du code normal que vous
pouvez lire et éditer :

- `app/models/user.rb` — un modèle `User` avec `has_secure_password`
  (mot de passe hashé via `bcrypt`, jamais stocké en clair).
- `app/models/session.rb` — un modèle `Session` qui appartient à un
  `User` : chaque connexion crée une session persistée en base, avec un
  jeton signé stocké dans un cookie.
- `app/models/current.rb` — un `ActiveSupport::CurrentAttributes` qui
  rend la session et l'utilisateur courants accessibles partout dans la
  requête (`Current.user`), sans avoir à les faire transiter en paramètre
  de méthode en méthode.
- `app/controllers/concerns/authentication.rb` — un concern inclus dans
  `ApplicationController`, qui fournit `require_authentication` (un
  `before_action`) et retrouve automatiquement la session à partir du
  cookie à chaque requête.
- `app/controllers/sessions_controller.rb` — les actions `new`/`create`
  (formulaire de connexion) et `destroy` (déconnexion).

```ruby
# app/models/user.rb (généré)
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
```

`has_secure_password` attend une colonne `password_digest` — déjà prévue
par la migration générée — et ajoute les méthodes `authenticate`,
`password=` et `password_confirmation=`.

## Créer un premier compte

Le générateur ne crée pas de formulaire d'inscription : dans un CRM
interne, les comptes du personnel sont créés à la main, pas par
auto-inscription publique.

```ruby
User.create!(email_address: "alice@association.org", password: "un-mot-de-passe-solide")
```

## Se connecter

`SessionsController#create` authentifie par email et mot de passe, puis
délègue la création de la session au concern :

```ruby
# app/controllers/sessions_controller.rb (généré, simplifié)
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))
    if user
      start_new_session_for(user)
      redirect_to root_path
    else
      redirect_to new_session_path, alert: "Email ou mot de passe incorrect."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
```

`start_new_session_for` (fourni par le concern `Authentication`) crée
l'enregistrement `Session`, signe un identifiant dans un cookie
`httponly`, et l'associe à `Current.session` pour le reste de la requête.

## Protéger un contrôleur

Par défaut, le concern rend **toute** l'application authentifiée : chaque
contrôleur qui hérite d'`ApplicationController` exige une session valide,
sauf déclaration explicite du contraire (`allow_unauthenticated_access`,
utilisé ci-dessus pour laisser `new`/`create` accessibles à un visiteur
non connecté — impossible de se connecter si la page de connexion exige
déjà d'être connecté).

```ruby
# app/controllers/donors_controller.rb
class DonorsController < ApplicationController
  # Rien à ajouter ici : l'authentification est déjà exigée par défaut.
end
```

Un visiteur non connecté qui tente d'accéder à `/donors` est redirigé
vers la page de connexion, avec l'URL demandée mémorisée pour y revenir
juste après.

## Rouvrir ce qui doit rester public

Ce nouveau réglage par défaut protège aussi `CampaignsController`, alors
que sa page (partie 2) a été construite précisément pour être partagée
publiquement par l'association, sans compte. Il faut l'exempter
explicitement — le même mécanisme que celui utilisé par
`SessionsController` généré plus haut :

```ruby
# app/controllers/campaigns_controller.rb
class CampaignsController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  def index
    @campaigns = Campaign.all
  end

  def show
    @campaign = Campaign.find(params[:id])
  end
end
```

`DonorsController`, lui, ne déclare rien de tel : il reste couvert par le
comportement par défaut, exactement comme l'exemple ci-dessus.

## S'authentifier dans les tests

Le générateur ajoute aussi `test/test_helpers/session_test_helper.rb`,
avec une méthode `sign_in_as(user)` déjà incluse dans
`ActionDispatch::IntegrationTest`. À partir de maintenant, tout test de
contrôleur ou système qui touche une page protégée doit d'abord
l'appeler — sans quoi il se heurtera à la même redirection vers la page
de connexion qu'un visiteur non identifié :

```ruby
test "an authenticated staff member can see the donors list" do
  sign_in_as(users(:staff))

  get donors_path

  assert_response :success
end
```

Pour un test système, qui pilote un vrai navigateur, l'équivalent
n'existe pas encore : il faut l'écrire une fois, dans
`test/application_system_test_case.rb`, pour que tous les tests système
puissent ensuite l'appeler exactement comme `sign_in_as` ci-dessus.

```ruby
# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def sign_in_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Mot de passe", with: "password"
    click_on "Se connecter"
  end
end
```

## Exercices

**3.1 — Lancer le générateur d'authentification et migrer la base**

Dans `donor_crm`, exécutez `bin/rails generate authentication` puis
`bin/rails db:migrate`. Ouvrez les fichiers générés
(`app/models/user.rb`, `app/controllers/sessions_controller.rb`,
`app/controllers/concerns/authentication.rb`) et repérez la déclaration
`has_secure_password`.

**3.2 — Créer un premier compte staff depuis la console**

Depuis `bin/rails console`, créez un utilisateur avec un email et un mot
de passe. Vérifiez que `User.authenticate_by(email_address: "...",
password: "...")` retourne bien cet utilisateur, et qu'un mauvais mot de
passe retourne `nil`.

**3.3 — Se connecter et se déconnecter depuis le navigateur**

Lancez `bin/rails server`, visitez `/session/new`, connectez-vous avec le
compte créé, puis déconnectez-vous. Vérifiez que le cookie de session
disparaît après déconnexion (outils de développement du navigateur).

**3.4 — Protéger `DonorsController` avec `require_authentication`**

Vérifiez qu'un visiteur non connecté qui tente `/donors` est bien
redirigé vers la page de connexion. Ajoutez ensuite
`allow_unauthenticated_access only: %i[index show]` à
`CampaignsController` et vérifiez, à l'inverse, que sa page reste
accessible sans être connecté.

**3.5 — Personnaliser le message de redirection**

Dans le concern `Authentication`, repérez où est défini le message
affiché lors d'une redirection pour authentification manquante.
Changez-le pour quelque chose de plus parlant pour l'équipe, par exemple
« Connectez-vous pour accéder au CRM de dons. »
