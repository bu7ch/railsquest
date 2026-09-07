class ChaptersController < ApplicationController
  def show
    @part = ContentLoader.parts.find { |part| part.slug == params[:part_slug] }
    raise ActionController::RoutingError, "Part not found" unless @part

    @chapter = @part.chapters.find { |chapter| chapter.slug == params[:slug] }
    raise ActionController::RoutingError, "Chapter not found" unless @chapter

    @completed_keys = logged_in? ? current_user.exercise_completions.pluck(:exercise_key) : []
  end
end
