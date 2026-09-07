---
name: RailsQuest
description: Cours Rails façon revue à numéros — chaque Partie est un numéro d'une même collection.
colors:
  paper: "#f3eee3"
  paper-raised: "#ebe4d3"
  ink: "#17140f"
  ink-secondary: "#5b5648"
  ink-faint: "#8c8672"
  rule: "#d8d0ba"
  code-bg: "#1b1710"
  code-fg: "#efe8d8"
  code-fg-dim: "#a89f88"
  accent-0-rouille: "#b5451d"
  accent-1-cobalt: "#2e5c8a"
  accent-2-vert-bouteille: "#2f6b4f"
  accent-3-prune: "#6b3a5c"
  accent-4-ocre: "#8a661c"
  accent-5-petrole: "#1e6b72"
  accent-6-corail: "#a34b4b"
  accent-7-indigo: "#3b3b78"
typography:
  display:
    fontFamily: "Source Serif 4, Georgia, serif"
    fontSize: "clamp(2.4rem, 6vw, 4.4rem)"
    fontWeight: 700
    lineHeight: 0.98
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Source Serif 4, Georgia, serif"
    fontSize: "clamp(1.6rem, 3vw, 2.5rem)"
    fontWeight: 600
    lineHeight: 1.1
  body:
    fontFamily: "Source Serif 4, Georgia, serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Source Sans 3, -apple-system, sans-serif"
    fontSize: "0.82rem"
    fontWeight: 700
    letterSpacing: "0.04em"
  mono:
    fontFamily: "JetBrains Mono, ui-monospace, monospace"
    fontSize: "0.85rem"
    fontWeight: 400
spacing:
  1: "0.5rem"
  2: "0.875rem"
  3: "1.5rem"
  4: "2.5rem"
  5: "4rem"
  6: "6rem"
components:
  button-primary:
    backgroundColor: "{colors.accent-0-rouille}"
    textColor: "{colors.paper}"
    padding: "0.75em 1.4em"
  button-primary-hover:
    backgroundColor: "{colors.ink}"
  button-plain:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    padding: "0.4em 0.9em"
  button-plain-hover:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.paper}"
---

# Design System: RailsQuest

## Overview

**Creative North Star: "La revue à numéros"**

RailsQuest se pense comme une collection de numéros de revue plutôt que comme une plateforme de cours en ligne. Chaque Partie du cursus est un numéro : elle porte sa propre encre d'accompagnement, son propre bandeau, sa propre marque géométrique — jamais le même accent partout, jamais une grille de cartes SaaS interchangeables. Le fond reste un papier crème constant et l'encre quasi-noire porte tout le texte courant ; seule la couleur d'un numéro change d'une Partie à l'autre, exactement comme la couleur d'accompagnement d'un numéro de revue imprimée.

Le rejet explicite est le gabarit « plateforme de cours en ligne » générique : hero arrondi, dégradés, cartes à icônes identiques, kickers au-dessus des titres. RailsQuest est éditorial, sobre, dense en texte — un manuel technique relié en revue, pas un produit SaaS.

**Key Characteristics:**
- Fond papier crème constant, encre quasi-noire pour tout le texte courant.
- Une encre d'accompagnement par Partie (8 teintes sourdes assignées), jamais dans le corps de texte.
- Titres en serif surdimensionné aligné à gauche, façon couverture de numéro.
- Aucune ombre, aucun dégradé, aucun coin arrondi prononcé — surfaces plates, séparées par des filets.
- Code affiché sur un panneau encre foncée, jamais sur le papier clair.

## Colors

Palette restreinte : un fond et une encre constants, plus une encre d'accompagnement qui change selon la Partie affichée — jamais plus d'une couleur active à la fois sur un écran donné.

### Primary
- **Rouille** (#b5451d) : encre d'accompagnement de la Partie 0 ; couleur du bouton d'action principal (« Commencer ») sur la page d'accueil.

### Secondary — les 7 autres encres d'accompagnement
- **Cobalt** (#2e5c8a) : Partie 1.
- **Vert bouteille** (#2f6b4f) : Partie 2.
- **Prune** (#6b3a5c) : Partie 3.
- **Ocre** (#8a661c) : Partie 4 — volontairement assombri par rapport à un ocre franc (#b08a2e initial) pour tenir le seuil de contraste 4.5:1 sur papier crème.
- **Pétrole** (#1e6b72) : Partie 5.
- **Corail** (#a34b4b) : Partie 6.
- **Indigo** (#3b3b78) : Partie 7.

### Neutral
- **Papier** (#f3eee3) : fond de toute page.
- **Papier ombré** (#ebe4d3) : fond des panneaux de marque, du code inline, des surfaces légèrement en retrait.
- **Encre** (#17140f) : texte courant, titres.
- **Encre secondaire** (#5b5648) : légendes, méta-texte, labels de navigation — toujours ≥4.5:1 sur papier.
- **Encre effacée** (#8c8672) : décorative uniquement (bordures de boutons inactifs, trait de barré) — jamais utilisée comme couleur de texte, son contraste sur papier (≈3.15:1) est sous le seuil de lisibilité.
- **Filet** (#d8d0ba) : toutes les règles de séparation horizontales.

### Named Rules
**The One Accent Rule.** Une seule encre d'accompagnement est active par écran, dérivée du numéro de Partie affiché (`--part-accent`). Le corps de texte ne porte jamais cette couleur — seuls le bandeau, le numéro, la marque et les contrôles actifs la portent.

**The No Faint Text Rule.** `--ink-faint` n'est jamais une couleur de texte ; elle échoue au seuil de contraste 4.5:1. Tout texte, même secondaire, utilise `--ink-secondary` au minimum.

## Typography

**Display Font:** Source Serif 4 (avec repli Georgia, serif)
**Body Font:** Source Serif 4 (avec repli Georgia, serif)
**Label/Mono Font:** Source Sans 3 pour la navigation et les labels ; JetBrains Mono pour le code

**Character:** Une seule famille serif porte à la fois les titres et le corps de texte, dans le registre d'un vrai livre technique ; Source Sans 3 n'intervient que pour la navigation et les petites capitales, jamais pour du texte de lecture longue.

### Hierarchy
- **Display** (700, `clamp(2.4rem, 6vw, 4.4rem)`, line-height 0.98) : titre de couverture de la Partie 0 sur l'accueil, aligné à gauche, jamais centré.
- **Headline** (600, `clamp(1.6rem, 3vw, 2.5rem)`, line-height 1.1) : titres de Partie et de chapitre.
- **Body** (400, 1.0625rem, line-height 1.55) : tout le texte courant, mesure limitée à 68ch pour la lecture longue.
- **Label** (700, 0.82rem, tracking 0.04em, Source Sans 3) : navigation, statuts (« à venir »), légendes de section — jamais en position de kicker au-dessus d'un titre.
- **Mono** (400, 0.85rem, JetBrains Mono) : blocs de code et clés d'exercice uniquement — jamais utilisé comme costume « technique » ailleurs.

### Named Rules
**The Single Serif Rule.** Une seule famille serif (Source Serif 4) porte titres et corps de texte. Source Sans 3 est réservé à la chrome (nav, labels, statuts) et n'apparaît jamais dans le texte de lecture.

## Layout

Page conteneur à `max-width: 76rem`, centrée, avec un padding horizontal de `2.5rem` (`1.5rem` sous 720px). Le texte de lecture est plafonné à `68ch` pour rester confortable même dans une colonne large.

Deux grilles éditoriales à deux colonnes structurent les pages à contenu riche : la page de chapitre (`minmax(0, 42rem) 1fr` — colonne de lecture + colonne latérale sommaire/exercices, sticky) et la page de Partie / la page de progression (`minmax(0, 42rem) 1fr` — liste + panneau de marque). Les deux collapsent en une colonne sous 960px, le panneau latéral remontant au-dessus du contenu principal en mobile.

Le sommaire de la page d'accueil passe en deux colonnes CSS (`columns: 2`) au-delà de 900px, avec `break-inside: avoid` sur chaque entrée.

Échelle d'espacement : `0.5rem / 0.875rem / 1.5rem / 2.5rem / 4rem / 6rem`, utilisée de façon croissante entre groupes serrés et sections séparées — toujours plus d'espace au-dessus d'un titre qu'en dessous.

## Elevation & Depth

Système plat : aucune ombre portée nulle part. La profondeur se lit par le contraste papier/encre et par les filets de séparation (`--rule`), jamais par un `box-shadow`. Les panneaux de marque et le fond de code se distinguent par une valeur de fond différente (papier ombré, ou encre foncée pour le code), pas par une élévation simulée.

### Named Rules
**The Flat-By-Default Rule.** Aucune ombre, aucun flou, aucun effet de verre. Une surface se distingue du papier par sa couleur de fond ou une bordure fine, jamais par une ombre.

## Shapes

Langage rectiligne : pas de coin arrondi prononcé nulle part, à l'exception du code inline (`border-radius: 3px`, un compromis de lisibilité mineur). Boutons, panneaux et cartes de marque sont des rectangles nets. Les seules ruptures de la grille rectiligne sont les filets horizontaux (`1px solid var(--rule)`) qui séparent les entrées de liste, et les bandeaux de 3px dans l'encre d'accompagnement qui marquent le haut de chaque page de Partie/chapitre.

## Components

### Buttons
- **Shape :** rectangle net, aucun radius (0).
- **Primary (« Commencer ») :** fond `--accent-0` (ou l'encre d'accompagnement active), texte papier, padding `0.75em 1.4em`, petites capitales tracées.
- **Plain (connexion, déconnexion, bascule d'exercice) :** fond transparent, bordure 1px encre, devient plein (fond encre / texte papier) au survol.
- **Hover / Focus :** transition de fond immédiate (pas de délai), `outline: 2px solid var(--ink)` au focus clavier — jamais l'anneau bleu par défaut du navigateur.

### Cards / Panels (panneaux de marque)
- **Corner Style :** aucun radius.
- **Background :** `--paper-raised`, ou une teinte de l'encre d'accompagnement à 10% d'opacité (`color-mix`) sur la couverture et la page de Partie.
- **Shadow Strategy :** aucune — voir Elevation.
- **Border :** aucune ; le panneau se distingue par sa couleur de fond seule.

### Navigation (masthead)
- **Style :** nom du site en petites capitales tracées (Source Sans 3, 700), liens/boutons alignés à droite, séparés du contenu par un filet fin.
- **États :** les boutons pleins (`button-plain`) inversent fond/texte au survol ; aucun style actif distinct pour le lien de progression.
- **Mobile :** la barre reste sur une ligne avec retour à la ligne naturel si nécessaire ; pas de menu hamburger (peu d'entrées).

### Signature Component — le bandeau de Partie (`issue-header` / `chapter-header`)
Chaque page de Partie et de chapitre ouvre sur un bandeau de 3px dans l'encre d'accompagnement de la Partie, avec le numéro en grand serif coloré à gauche et une petite marque géométrique (« rail à deux barres », `rail_mark` dans `ApplicationHelper`) à droite. C'est le seul endroit où la couleur d'accompagnement porte du texte à grande échelle (le numéro lui-même) ; partout ailleurs elle reste un accent de bordure ou de contrôle.

### Code blocks
- **Style :** fond `--code-bg` (#1b1710), texte `--code-fg` (#efe8d8), police JetBrains Mono, aucun radius, pas de bordure.
- **Coloration syntaxique :** palette dédiée sur fond sombre (voir `.highlight .c/.k/.s/.nc/...` dans `application.css`), indépendante des encres d'accompagnement — la coloration du code ne change jamais avec la Partie affichée.

## Do's and Don'ts

### Do:
- **Do** dériver la couleur d'accent d'une page de son numéro de Partie (`part_accent(number)`), jamais d'une valeur codée en dur.
- **Do** garder le texte courant en `--ink` ou `--ink-secondary` uniquement — jamais en couleur d'accompagnement, jamais en `--ink-faint`.
- **Do** utiliser des filets (`1px solid var(--rule)`) pour séparer des entrées de liste, jamais une carte avec ombre.
- **Do** dessiner les icônes en SVG au même poids de trait que la navigation (voir `back_arrow`, `rail_mark`) — jamais un glyphe unicode en guise d'icône.

### Don't:
- **Don't** ajouter de kicker ou d'eyebrow au-dessus d'un titre — le titre porte sa propre information (le numéro de Partie s'intègre dans le H1 lui-même, jamais au-dessus).
- **Don't** utiliser le gabarit « gros chiffre + petit label » (hero-metric) pour afficher une statistique — c'est un défaut connu de la page de progression actuelle, pas une règle du système à reproduire ailleurs.
- **Don't** répéter la marque géométrique (`rail_mark`) plus d'une fois par page dans une intention purement décorative — sa valeur tient à sa rareté ; l'utiliser deux fois sur la page de Partie actuelle est un défaut constaté, pas un pattern à généraliser.
- **Don't** introduire d'ombre portée, de dégradé, de flou décoratif ou de coin arrondi prononcé nulle part dans le système.
