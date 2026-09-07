class PagesController < ApplicationController
  def home
    @parts = ContentLoader.parts
  end
end
