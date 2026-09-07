class PartsController < ApplicationController
  def show
    @part = ContentLoader.parts.find { |part| part.slug == params[:slug] }
    raise ActionController::RoutingError, "Part not found" unless @part
  end
end
