require "test_helper"
require "tmpdir"
require "fileutils"

class ContentLoaderTest < ActiveSupport::TestCase
  def loader
    ContentLoader.new(root: Rails.root.join("test/fixtures/content/parts"))
  end

  test "parses parts sorted by number" do
    parts = loader.parts

    assert_equal [ 0, 1 ], parts.map(&:number)
    assert_equal [ "Sample Part", "Second Part" ], parts.map(&:title)
  end

  test "a part with no chapter files has an empty chapters list" do
    second_part = loader.parts.find { |p| p.number == 1 }

    assert_equal [], second_part.chapters
    assert_equal "coming_soon", second_part.status
  end

  test "parses chapter title, exercises and renders markdown body to HTML" do
    chapter = loader.parts.first.chapters.first

    assert_equal "First Chapter", chapter.title
    assert_equal [ Content::Exercise.new(key: "0.1", title: "Do the first thing") ], chapter.exercises
    assert_includes chapter.body_html, "<h1"
    assert_includes chapter.body_html, "<strong>bold</strong>"
    assert_includes chapter.body_html, "highlight"
  end

  test "chapter slug strips numeric prefix and extension" do
    chapter = loader.parts.first.chapters.first

    assert_equal "first-chapter", chapter.slug
  end

  test "a leading heading matching the chapter title is stripped, since the page chrome renders it" do
    chapter = loader.parts.first.chapters.first

    assert_not_includes chapter.body_html, "First Chapter"
    assert_includes chapter.body_html, "<h1"
    assert_includes chapter.body_html, "Introduction"
  end

  test "a leading heading that does not match the chapter title is preserved" do
    Dir.mktmpdir do |dir|
      part_dir = Pathname.new(dir).join("00-part")
      FileUtils.mkdir_p(part_dir)
      File.write(part_dir.join("part.yml"), { "number" => 0, "title" => "Part", "status" => "written" }.to_yaml)
      File.write(part_dir.join("01-chapter.md"), <<~MARKDOWN)
        ---
        title: "Chapter"
        exercises: []
        ---

        # A different heading

        Body text.
      MARKDOWN

      chapter = ContentLoader.new(root: Pathname.new(dir)).parts.first.chapters.first

      assert_includes chapter.body_html, "A different heading"
    end
  end

  test "raises InvalidContentError when exercise keys collide across chapters" do
    dup_loader = ContentLoader.new(root: Rails.root.join("test/fixtures/invalid_content/parts"))

    assert_raises(ContentLoader::InvalidContentError) { dup_loader.parts }
  end

  test "raises InvalidContentError when part status is not written or coming_soon" do
    Dir.mktmpdir do |dir|
      part_dir = Pathname.new(dir).join("00-bad-status")
      FileUtils.mkdir_p(part_dir)
      File.write(part_dir.join("part.yml"), { "number" => 0, "title" => "Bad", "status" => "draft" }.to_yaml)

      bad_loader = ContentLoader.new(root: Pathname.new(dir))

      assert_raises(ContentLoader::InvalidContentError) { bad_loader.parts }
    end
  end

  test "class method .parts delegates to the real content directory" do
    assert ContentLoader.parts.is_a?(Array)
    assert ContentLoader.parts.all? { |part| part.is_a?(Content::Part) }
  end

  test "the real course content has 8 parts, 4-7 coming soon with no chapters" do
    parts = ContentLoader.parts
    coming_soon = parts.select { |p| p.number.between?(4, 7) }

    assert_equal [ 4, 5, 6, 7 ], coming_soon.map(&:number)
    assert coming_soon.all? { |p| p.status == "coming_soon" }
    assert coming_soon.all? { |p| p.chapters.empty? }
  end

  test "part 0 is written with 2 chapters and 3 exercises" do
    part0 = ContentLoader.parts.find { |p| p.number == 0 }

    assert_equal "written", part0.status
    assert_equal 2, part0.chapters.size
    assert_equal [ "0.1", "0.2", "0.3" ], part0.exercises.map(&:key)
  end

  test "part 1 is written with 2 chapters and 4 exercises" do
    part1 = ContentLoader.parts.find { |p| p.number == 1 }

    assert_equal "written", part1.status
    assert_equal 2, part1.chapters.size
    assert_equal [ "1.1", "1.2", "1.3", "1.4" ], part1.exercises.map(&:key)
  end

  test "part 2 is written with 2 chapters and 3 exercises" do
    part2 = ContentLoader.parts.find { |p| p.number == 2 }

    assert_equal "written", part2.status
    assert_equal 2, part2.chapters.size
    assert_equal [ "2.1", "2.2", "2.3" ], part2.exercises.map(&:key)
  end

  test "part 3 is written with 2 chapters and 10 exercises" do
    part3 = ContentLoader.parts.find { |p| p.number == 3 }

    assert_equal "written", part3.status
    assert_equal 2, part3.chapters.size
    assert_equal(
      [ "3.1", "3.2", "3.3", "3.4", "3.5", "3.6", "3.7", "3.8", "3.9", "3.10" ],
      part3.exercises.map(&:key)
    )
  end

  test "all written parts together expose 20 exercises with globally unique keys" do
    all_keys = ContentLoader.parts.flat_map(&:exercises).map(&:key)

    assert_equal 20, all_keys.size
    assert_equal all_keys, all_keys.uniq
  end
end
