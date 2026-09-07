class ExerciseCompletionsController < ApplicationController
  before_action :require_login

  def create
    current_user.exercise_completions.find_or_create_by!(exercise_key: params[:exercise_key])
    render_exercise_state(params[:exercise_key], completed: true)
  end

  def destroy
    current_user.exercise_completions.find_by(exercise_key: params[:exercise_key])&.destroy
    render_exercise_state(params[:exercise_key], completed: false)
  end

  private

  def render_exercise_state(exercise_key, completed:)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "exercise_#{exercise_key.parameterize}",
          partial: "chapters/exercise",
          locals: { exercise_key: exercise_key, completed: completed }
        )
      end
      format.html { head :ok }
    end
  end
end
