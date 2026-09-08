# RailsQuest

Un cours Rails en ligne inspiré de [Full Stack Open](https://fullstackopen.com/en/) :
un parcours structuré en 8 parties, avec un seul fil rouge applicatif —
un CRM de dons pour une association (`Donor`, `Campaign`, `Donation`) —
construit progressivement de la partie 0 à la partie 7.

Le contenu du cours vit dans ce dépôt sous forme de Markdown
(`content/parts/`) ; RailsQuest lui-même est le site qui l'affiche et
suit la progression de chaque apprenant, pas l'endroit où le fil rouge
tourne (l'apprenant le construit sur sa propre machine).

## Stack

- Ruby 4.0.5, Rails 8.1
- SQLite (base applicative + Solid Cache/Queue/Cable)
- Hotwire (Turbo + Stimulus), sans framework JS ni CSS ajouté
- Kramdown + Rouge pour le rendu du contenu Markdown et la coloration syntaxique
- Minitest pour les tests (unitaires, intégration, système via Capybara)
- Connexion visiteur via GitHub OAuth (uniquement pour le suivi de progression)

## Prérequis

- Ruby 4.0.5 (voir `.ruby-version`)
- SQLite3

## Installation

```bash
bin/setup
```

Ce script installe les gems, prépare la base de données, et démarre le
serveur de développement. Pour l'exécuter sans lancer le serveur :

```bash
bin/setup --skip-server
```

### Connexion GitHub (optionnel)

Tout le contenu du cours est lisible sans compte. Se connecter via
GitHub (pour cocher des exercices et suivre sa progression) demande une
[OAuth App GitHub](https://github.com/settings/developers) dont les
identifiants sont chiffrés dans les credentials Rails :

```bash
bin/rails credentials:edit
```

```yaml
github:
  client_id: ...
  client_secret: ...
```

## Lancer le serveur

```bash
bin/dev
```

L'application est servie sur `http://localhost:3000`.

## Tests

```bash
PARALLEL_WORKERS=1 bin/rails test
PARALLEL_WORKERS=1 bin/rails test:system
```

`PARALLEL_WORKERS=1` est nécessaire : la parallélisation par fork de
Minitest se comporte mal au-delà d'un worker dans cet environnement.

## Qualité de code

```bash
bin/rubocop
bin/brakeman
```

## Structure du contenu

Chaque partie du cours vit dans `content/parts/<NN-slug>/` :

```
content/parts/01-modeles-activerecord/
├── part.yml                        # numéro, titre, statut (written / coming_soon)
├── 01-migrations-et-modeles.md     # un chapitre : front matter + Markdown
└── 02-associations-et-validations.md
```

Chaque fichier de chapitre porte un front matter YAML (`title`,
`exercises: [{key, title}]`) suivi du corps en Markdown. Le contenu
n'est jamais stocké en base de données — `ContentLoader` le parse
directement depuis le dépôt à chaque requête (mis en cache en
production).

## Documentation additionnelle

- [`PRODUCT.md`](PRODUCT.md) — contexte produit
- [`DESIGN.md`](DESIGN.md) — système de design
