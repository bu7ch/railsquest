class ProgressController < ApplicationController
  before_action :require_login

  def show
    @parts = ContentLoader.parts.select(&:written?)
    @completed_keys = current_user.exercise_completions.pluck(:exercise_key)
  end
end
