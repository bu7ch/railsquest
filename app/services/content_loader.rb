require "yaml"
require "kramdown"

class ContentLoader
  class InvalidContentError < StandardError; end

  VALID_STATUSES = %w[written coming_soon].freeze

  def self.parts
    if Rails.env.production?
      Rails.cache.fetch("content_loader/parts/#{content_version}") { new(root: default_root).parts }
    else
      new(root: default_root).parts
    end
  end

  def self.default_root
    Rails.root.join("content", "parts")
  end

  def self.content_version
    Dir.glob(default_root.join("**/*")).map { |f| File.mtime(f).to_i }.max
  end

  def initialize(root:)
    @root = root
  end

  def parts
    parsed = Dir.children(@root).sort.map { |dirname| parse_part(@root.join(dirname)) }
    validate!(parsed)
    parsed.sort_by(&:number)
  end

  private

  def parse_part(part_dir)
    meta = YAML.safe_load_file(part_dir.join("part.yml"))
    chapters = chapter_files(part_dir).map { |file| parse_chapter(file) }

    Content::Part.new(
      number: meta.fetch("number"),
      slug: File.basename(part_dir),
      title: meta.fetch("title"),
      status: meta.fetch("status"),
      chapters: chapters
    )
  end

  def chapter_files(part_dir)
    Dir.glob(part_dir.join("*.md")).sort
  end

  def parse_chapter(file_path)
    front_matter, body = split_front_matter(File.read(file_path))
    meta = YAML.safe_load(front_matter) || {}
    exercises = (meta["exercises"] || []).map do |ex|
      Content::Exercise.new(key: ex.fetch("key"), title: ex.fetch("title"))
    end

    title = meta.fetch("title")

    Content::Chapter.new(
      slug: File.basename(file_path, ".md").sub(/\A\d+-/, ""),
      title: title,
      exercises: exercises,
      body_html: render_markdown(strip_redundant_heading(body, title))
    )
  end

  # The page chrome already renders the chapter title as its <h1>; a
  # Markdown body that repeats it as its own leading "# Title" would
  # otherwise print the same heading twice.
  def strip_redundant_heading(body, title)
    body.sub(/\A\s*# #{Regexp.escape(title)}\s*\n/, "")
  end

  def split_front_matter(raw)
    return [ "", raw ] unless raw.start_with?("---")

    _, front_matter, body = raw.split(/^---\s*$/, 3)
    [ front_matter, body ]
  end

  def render_markdown(body)
    Kramdown::Document.new(body, input: "GFM", syntax_highlighter: "rouge", hard_wrap: false).to_html
  end

  def validate!(parts)
    parts.each do |part|
      unless VALID_STATUSES.include?(part.status)
        raise InvalidContentError, "part #{part.slug} has invalid status #{part.status.inspect}"
      end
    end

    numbers = parts.map(&:number)
    if numbers.uniq.length != numbers.length
      raise InvalidContentError, "duplicate part numbers: #{numbers}"
    end

    keys = parts.flat_map(&:exercises).map(&:key)
    if keys.uniq.length != keys.length
      duplicates = keys.tally.select { |_, count| count > 1 }.keys
      raise InvalidContentError, "duplicate exercise keys: #{duplicates}"
    end
  end
end
