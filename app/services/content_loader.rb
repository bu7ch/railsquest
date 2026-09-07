require "yaml"
require "kramdown"

class ContentLoader
  class InvalidContentError < StandardError; end

  def initialize(root:)
    @root = root
  end

  def parts
    Dir.children(@root).sort.map { |dirname| parse_part(@root.join(dirname)) }
              .sort_by(&:number)
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

    Content::Chapter.new(
      slug: File.basename(file_path, ".md").sub(/\A\d+-/, ""),
      title: meta.fetch("title"),
      exercises: exercises,
      body_html: render_markdown(body)
    )
  end

  def split_front_matter(raw)
    return ["", raw] unless raw.start_with?("---")

    _, front_matter, body = raw.split(/^---\s*$/, 3)
    [front_matter, body]
  end

  def render_markdown(body)
    Kramdown::Document.new(body, input: "GFM", syntax_highlighter: "rouge").to_html
  end
end
