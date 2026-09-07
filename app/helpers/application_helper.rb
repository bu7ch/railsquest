module ApplicationHelper
  PART_ACCENTS = {
    0 => "#B5451D", # rouille
    1 => "#2E5C8A", # cobalt
    2 => "#2F6B4F", # vert bouteille
    3 => "#6B3A5C", # prune
    4 => "#8A661C", # ocre
    5 => "#1E6B72", # pétrole
    6 => "#A34B4B", # corail
    7 => "#3B3B78"  # indigo
  }.freeze

  def part_accent(number)
    PART_ACCENTS.fetch(number % PART_ACCENTS.size)
  end

  # A small abstract mark — two rails and their ties — that reappears once
  # per Partie in that Partie's own accent color.
  # A small left-pointing arrow, drawn to match the nav stroke weight —
  # used instead of a unicode "←" glyph.
  def back_arrow
    content_tag(:svg, viewBox: "0 0 16 16", width: 14, height: 14, class: "back-arrow",
                fill: "none", stroke: "currentColor", "stroke-width": 1.6,
                "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": "true") do
      safe_join([
        tag.polyline(points: "9 3 3 8 9 13"),
        tag.line(x1: 3, y1: 8, x2: 14, y2: 8)
      ])
    end
  end

  def rail_mark(color: "currentColor", size: 28)
    content_tag(:svg, viewBox: "0 0 32 32", width: size, height: size, class: "rail-mark",
                fill: "none", stroke: color, "stroke-width": 2, "aria-hidden": "true") do
      safe_join([
        tag.line(x1: 6, y1: 4, x2: 6, y2: 28),
        tag.line(x1: 26, y1: 4, x2: 26, y2: 28),
        tag.line(x1: 6, y1: 9, x2: 26, y2: 9),
        tag.line(x1: 6, y1: 16, x2: 26, y2: 16),
        tag.line(x1: 6, y1: 23, x2: 26, y2: 23)
      ])
    end
  end
end
