---
title: "Anatomie d'une application générée"
exercises:
  - key: "0.3"
    title: "Modifier la page d'accueil par défaut"
---

# Anatomie d'une application générée

`rails new` génère une arborescence complète. Voici les dossiers que vous
utiliserez le plus dans ce cours :

- `app/` — le code de l'application (modèles, vues, contrôleurs, jobs,
  mailers...).
- `config/` — configuration, dont `config/routes.rb` qui définit les URLs
  de l'application.
- `db/` — les migrations (évolutions du schéma de base de données) et
  `db/schema.rb` (l'état courant du schéma).
- `test/` — les tests automatisés, écrits avec Minitest par défaut.

## `config/routes.rb`

C'est le point d'entrée de toute requête : Rails y cherche quelle
combinaison contrôleur/action doit traiter une URL donnée.

```ruby
Rails.application.routes.draw do
  root "pages#home"
end
```

Ici, une requête sur `/` est dirigée vers l'action `home` de
`PagesController`.

## Le serveur de développement

`bin/rails server` recharge automatiquement votre code à chaque requête en
développement — pas besoin de redémarrer le serveur après avoir modifié un
contrôleur ou une vue.

## Exercices

**0.3 — Modifier la page d'accueil par défaut**

Dans votre projet `donor_crm`, créez un contrôleur `PagesController` avec
une action `home`, une vue correspondante affichant "Bienvenue sur le CRM
de dons", et faites pointer `root` vers cette action dans
`config/routes.rb`. Vérifiez dans le navigateur.
