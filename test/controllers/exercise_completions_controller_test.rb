require "test_helper"

class ExerciseCompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(github_id: "1", username: "alice")
  end

  test "create requires login" do
    post exercise_completions_path, params: { exercise_key: "0.1" }

    assert_redirected_to root_path
  end

  test "create marks the exercise done for the logged-in user" do
    sign_in_as(@user)

    assert_difference "@user.exercise_completions.count", 1 do
      post exercise_completions_path, params: { exercise_key: "0.1" }
      @user.reload
    end
    assert_response :success
  end

  test "destroy un-marks the exercise for the logged-in user" do
    sign_in_as(@user)
    @user.exercise_completions.create!(exercise_key: "0.1")

    assert_difference "@user.exercise_completions.count", -1 do
      delete exercise_completion_path("0.1")
      @user.reload
    end
    assert_response :success
  end

  private

  def sign_in_as(user)
    post "/session_for_test", params: { user_id: user.id }
  end
end
