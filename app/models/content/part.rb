module Content
  class Part
    attr_reader :number, :slug, :title, :status, :chapters

    def initialize(number:, slug:, title:, status:, chapters:)
      @number = number
      @slug = slug
      @title = title
      @status = status
      @chapters = chapters
    end

    def written?
      status == "written"
    end

    def exercises
      chapters.flat_map(&:exercises)
    end
  end
end
