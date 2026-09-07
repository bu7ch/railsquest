require "test_helper"

class Content::PartTest < ActiveSupport::TestCase
  test "written? is true only when status is written" do
    written = Content::Part.new(number: 0, slug: "00-fondamentaux", title: "Fondamentaux",
                                 status: "written", chapters: [])
    coming_soon = Content::Part.new(number: 3, slug: "03-auth", title: "Auth",
                                     status: "coming_soon", chapters: [])

    assert written.written?
    assert_not coming_soon.written?
  end

  test "exercises flattens exercises across all chapters" do
    chapter_a = Content::Chapter.new(
      slug: "mvc", title: "MVC",
      exercises: [ Content::Exercise.new(key: "0.1", title: "Installer Rails") ],
      body_html: "<p>...</p>"
    )
    chapter_b = Content::Chapter.new(
      slug: "premiere-app", title: "Première app",
      exercises: [ Content::Exercise.new(key: "0.2", title: "Explorer l'anatomie") ],
      body_html: "<p>...</p>"
    )
    part = Content::Part.new(number: 0, slug: "00-fondamentaux", title: "Fondamentaux",
                              status: "written", chapters: [ chapter_a, chapter_b ])

    assert_equal [ "0.1", "0.2" ], part.exercises.map(&:key)
  end
end
