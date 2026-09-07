# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Développeurs déjà à l'aise avec la programmation (un autre langage, ou Ruby sans Rails), débutants sur Ruby on Rails. On ne réenseigne pas les bases de la programmation — le cours part directement des conventions et de la philosophie Rails.

## Product Purpose

RailsQuest est un cours Rails en ligne, inspiré de [Full Stack Open](https://fullstackopen.com/en/) : un parcours structuré en parties/chapitres, rédigé par l'auteur du projet, avec un fil rouge applicatif construit progressivement par l'apprenant sur sa propre machine (RailsQuest n'héberge pas ce code, il l'enseigne). Le site combine le contenu pédagogique et une plateforme légère de suivi de progression.

Succès = un développeur qui ne connaît pas encore Rails peut suivre le cours de bout en bout, comprendre les conventions du framework, et reproduire chez lui un vrai projet Rails multi-couches (modèles, contrôleurs, vues, auth, tests, Hotwire, jobs).

## Positioning

Un cours Rails gratuit et ouvert, au format « Full Stack Open mais pour Rails » : un seul projet fil rouge cohérent du début à la fin (pas des mini-exercices déconnectés), avec suivi de progression léger sans jamais devenir une plateforme de correction/notation. Le fil rouge choisi — un CRM de dons pour une association — est un domaine métier réaliste (rôles, rapports, données relationnelles) plutôt qu'un blog ou todo-list déjà vu partout.

## Operating Context

- L'apprenant lit le cours sur RailsQuest, mais code le fil rouge (un CRM de dons pour association : `Donor`, `Campaign`, `Donation`) sur sa propre machine, en local — RailsQuest ne l'héberge pas et ne le corrige pas.
- Le contenu du cours est écrit en Markdown, versionné dans le dépôt (`content/parts/`), édité directement par l'auteur — pas d'interface d'administration.
- Un visiteur peut lire tout le contenu sans compte. Se connecter (via GitHub OAuth) débloque uniquement le suivi de progression (cocher des exercices, voir un total par partie).
- Rédaction en français.

## Capabilities and Constraints

- 8 parties au sommaire (numérotées 0 à 7) ; à ce stade, les parties 0, 1 et 2 sont entièrement rédigées, les parties 3 à 7 sont marquées « à venir » (pas de contenu détaillé).
- Connexion visiteur via GitHub OAuth uniquement — pas de mot de passe, pas d'inscription par email.
- Le contenu du cours (parties/chapitres/exercices) n'est jamais stocké en base de données ; seules deux tables existent : `users` et `exercise_completions`.
- Pas de soumission d'exercices ni de correction automatique, pas de quiz notés, pas de certificat de fin de cours.
- Pas d'interface d'administration pour éditer le contenu — le contenu reste dans le dépôt Git, édité par l'auteur.
- Gratuit et ouvert sans restriction d'accès prévue ; le compte sert uniquement au suivi de progression, jamais à limiter l'accès au contenu.
- Stack : Rails 8, SQLite, Minitest, Kramdown + Rouge (rendu Markdown + coloration syntaxique), Hotwire (Turbo/Stimulus) — pas de framework JS ni de framework CSS ajouté.

## Brand Commitments

Nom du projet : RailsQuest. Aucune identité visuelle, palette, typographie ou logo n'a encore été établie — l'implémentation actuelle utilise le rendu HTML par défaut sans design system.

## Evidence on Hand

- Contenu réel et complet pour les parties 0 (`content/parts/00-fondamentaux/`), 1 (`content/parts/01-modeles-activerecord/`) et 2 (`content/parts/02-controleurs-vues-formulaires/`) : prose pédagogique en français, exemples de code Ruby/ERB, exercices.
- Spécification produit détaillée : `docs/superpowers/specs/2026-09-07-railsquest-design.md`.
- Aucun testimonial, étude de cas, logo ou asset de marque n'existe — à ne pas inventer.

## Product Principles

- Un seul fil rouge cohérent de bout en bout plutôt que des exercices isolés — chaque partie ajoute une couche au même projet.
- Le contenu prime sur la plateforme : la plateforme reste volontairement légère (progression seule, pas de correction/notation) pour ne jamais devenir plus complexe que le cours lui-même.
- Gratuit et ouvert par défaut ; aucune fonctionnalité ne doit restreindre l'accès au contenu derrière un compte ou un paiement.
- Le contenu est un artefact versionné (Markdown en dépôt Git), pas une donnée d'application — jamais de couplage à la base de données.

## Accessibility & Inclusion

Standards web usuels (contraste, navigation clavier, HTML sémantique) ; aucune exigence spécifique au-delà à ce stade.
