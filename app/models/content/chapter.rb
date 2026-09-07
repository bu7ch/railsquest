module Content
  class Chapter
    attr_reader :slug, :title, :exercises, :body_html

    def initialize(slug:, title:, exercises:, body_html:)
      @slug = slug
      @title = title
      @exercises = exercises
      @body_html = body_html
    end
  end
end
