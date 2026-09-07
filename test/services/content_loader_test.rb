require "test_helper"

class ContentLoaderTest < ActiveSupport::TestCase
  def loader
    ContentLoader.new(root: Rails.root.join("test/fixtures/content/parts"))
  end

  test "parses parts sorted by number" do
    parts = loader.parts

    assert_equal [0, 1], parts.map(&:number)
    assert_equal ["Sample Part", "Second Part"], parts.map(&:title)
  end

  test "a part with no chapter files has an empty chapters list" do
    second_part = loader.parts.find { |p| p.number == 1 }

    assert_equal [], second_part.chapters
    assert_equal "coming_soon", second_part.status
  end

  test "parses chapter title, exercises and renders markdown body to HTML" do
    chapter = loader.parts.first.chapters.first

    assert_equal "First Chapter", chapter.title
    assert_equal [Content::Exercise.new(key: "0.1", title: "Do the first thing")], chapter.exercises
    assert_includes chapter.body_html, "<h1"
    assert_includes chapter.body_html, "<strong>bold</strong>"
    assert_includes chapter.body_html, "highlight"
  end

  test "chapter slug strips numeric prefix and extension" do
    chapter = loader.parts.first.chapters.first

    assert_equal "first-chapter", chapter.slug
  end
end
