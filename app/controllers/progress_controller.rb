class ProgressController < ApplicationController
  before_action :require_login

  def show
    @parts = ContentLoader.parts.select(&:written?)
    @completed_keys = current_user.exercise_completions.pluck(:exercise_key)
    @next_exercise = find_next_exercise
  end

  private

  def find_next_exercise
    @parts.each do |part|
      part.chapters.each do |chapter|
        chapter.exercises.each do |exercise|
          next if @completed_keys.include?(exercise.key)

          return { part: part, chapter: chapter, exercise: exercise }
        end
      end
    end
    nil
  end
end
