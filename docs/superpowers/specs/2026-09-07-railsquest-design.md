# RailsQuest — Design

Date: 2026-09-07
Statut: approuvé pour planification

## 1. Objectif

RailsQuest est un site d'apprentissage de Ruby on Rails inspiré de
[fullstackopen.com](https://fullstackopen.com/en/) : un cours structuré en
parties/chapitres, rédigé par l'auteur du projet, avec un fil rouge
applicatif construit progressivement par l'apprenant, et une plateforme
légère de suivi de progression.

Public visé : développeurs déjà à l'aise avec la programmation, débutants
sur Rails. On ne réenseigne pas les bases de la programmation.

## 2. Répartition des responsabilités

Deux briques distinctes cohabitent dans la même appli Rails 8 :

- **Le contenu du cours** — statique, versionné en Markdown dans le dépôt
  (`content/parts/NN-slug/NN-slug.md`), sans base de données. Un
  `ContentLoader` parse ces fichiers (front-matter + corps Markdown) et
  expose des objets Ruby simples (`Part`, `Chapter`, `Exercise`).
- **La plateforme** — comptes visiteurs (OAuth GitHub) et suivi de
  progression (exercices cochés), qui se superpose au contenu.

Le fil rouge pédagogique (un CRM de dons pour association — `Donor`,
`Campaign`, `Donation`) **n'est pas hébergé par RailsQuest**. C'est le code
que l'apprenant écrit lui-même, sur sa propre machine, en suivant le cours.
RailsQuest ne fait qu'enseigner et montrer des extraits de code.

## 3. Curriculum

Plan complet en 8 parties, numérotées 0 à 7. Pour le lancement (MVP), les
parties 0, 1 et 2 sont entièrement rédigées ; les parties 3 à 7 apparaissent
au sommaire avec un badge « à venir » (chapitre placeholder, pas de contenu
détaillé).

| # | Titre | Contenu clé (illustré sur le CRM de dons) | MVP |
|---|---|---|---|
| 0 | Fondamentaux & philosophie Rails | MVC, convention over configuration, `rails new`, anatomie d'une appli, premier `rails server` | Rédigée |
| 1 | Modèles & ActiveRecord | Migrations, `Donor`/`Campaign`/`Donation`, associations, validations, console Rails | Rédigée |
| 2 | Contrôleurs, vues & formulaires | Routing REST, CRUD complet donateurs/campagnes, partials, flash, form helpers | Rédigée |
| 3 | Authentification & autorisation | Connexion staff (générateur d'auth Rails 8), rôles admin/collecteur de fonds, `before_action` | À venir |
| 4 | Tests | Minitest : tests modèle, contrôleur, système (Capybara) sur le CRM | À venir |
| 5 | Hotwire & Turbo | Tableau de bord des dons en direct (Turbo Streams), interactivité Stimulus | À venir |
| 6 | Jobs & emails | Reçu de don par email (Action Mailer), Active Job/Solid Queue | À venir |
| 7 | Déploiement | Kamal, prod-readiness | À venir |

## 4. Modèle de données

Le contenu (parties/chapitres/exercices) n'est pas en base — le
`ContentLoader` parse les fichiers Markdown au démarrage (résultat mis en
cache via `Rails.cache`) et expose des objets Ruby simples. Chaque exercice
porte une clé stable définie dans le front-matter de son chapitre (ex.
`"1.2"`), qui sert d'identifiant unique inter-sessions.

Seules deux tables en base :

- `users` — remplie via OAuth GitHub (`github_id`, `username`,
  `avatar_url`). Pas de mot de passe, pas d'inscription par email.
- `exercise_completions` — `user_id` (FK), `exercise_key` (string),
  `completed_at`. Une ligne par exercice coché par un utilisateur.

Ce découpage évite toute synchronisation fragile entre du contenu versionné
en fichiers et des enregistrements en base : le contenu peut être modifié
librement sans migration, et la progression reste valide tant que la clé
d'exercice ne change pas.

## 5. Authentification

Connexion via OAuth GitHub (gem `omniauth-github` + `omniauth-rails_csrf_protection`).
Au premier login, `find_or_create_by(github_id:)` crée l'utilisateur.
Session Rails classique (cookie signé), pas de mot de passe à gérer.

## 6. Pages

- **Accueil** — présentation du cours, sommaire des 8 parties avec statut
  (rédigée / à venir).
- **Page de partie** — liste des chapitres de la partie et de leurs
  exercices, avec progression de la partie si connecté.
- **Page de chapitre** — Markdown rendu (coloration syntaxique via Rouge),
  liste des exercices du chapitre avec checkbox (Turbo Stream, visible
  seulement si connecté ; sinon incite à se connecter).
- **Connexion** — bouton « Se connecter avec GitHub ».
- **Progression globale** — récapitulatif « X/Y exercices faits » par
  partie, pour l'utilisateur connecté.

## 7. Validation du contenu & gestion d'erreurs

Le `ContentLoader` valide le front-matter de chaque chapitre au démarrage
et en environnement de test : titre présent, exercices avec clés uniques
sur l'ensemble du cours. Un chapitre mal formé fait échouer le boot (dev/
test) plutôt que de produire une page cassée pour un visiteur en
production.

## 8. Tests

Minitest (cohérent avec les autres projets Rails de l'auteur) :

- Tests unitaires du `ContentLoader` sur des fixtures Markdown (parsing,
  validation, cas d'erreur).
- Tests modèle pour `User` et `ExerciseCompletion`.
- Tests contrôleur pour les pages de contenu (accueil, partie, chapitre).
- Tests système (Capybara) pour le parcours clé : connexion GitHub (mockée)
  → lecture d'un chapitre → coche un exercice → progression mise à jour.

## 9. Stack technique

Rails 8, SQLite, Solid Queue/Solid Cache (défauts Rails 8, cohérents avec
les autres projets). Rendu Markdown via Kramdown + Rouge. Pas de
frontend JS framework — Hotwire (Turbo/Stimulus) seulement, déjà inclus par
défaut dans Rails 8.

## 10. Hors périmètre (MVP)

- Soumission d'exercices / correction automatique.
- Quiz notés, certificats de fin de cours.
- Contenu détaillé des parties 3 à 7 (uniquement le plan/sommaire).
- Déploiement en production.
- Édition du contenu via interface admin (le contenu reste dans le dépôt,
  édité par l'auteur).
