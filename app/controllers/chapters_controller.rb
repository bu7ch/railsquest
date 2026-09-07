class ChaptersController < ApplicationController
  def show
    @part = ContentLoader.parts.find { |part| part.slug == params[:part_slug] }
    raise ActionController::RoutingError, "Part not found" unless @part

    @chapter = @part.chapters.find { |chapter| chapter.slug == params[:slug] }
    raise ActionController::RoutingError, "Chapter not found" unless @chapter
  end
end
