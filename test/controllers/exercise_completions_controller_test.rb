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

  test "create rejects an exercise_key that does not correspond to real content" do
    sign_in_as(@user)

    assert_no_difference "ExerciseCompletion.count" do
      post exercise_completions_path, params: { exercise_key: "99.99" }
    end
    assert_response :not_found
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

  test "create responds to a turbo_stream request with the exercise's real title" do
    sign_in_as(@user)

    post exercise_completions_path, params: { exercise_key: "0.1" }, as: :turbo_stream

    assert_response :success
    assert_match "Installer Rails et générer un projet vide", response.body
  end

  test "destroy responds to a turbo_stream request with the exercise's real title" do
    sign_in_as(@user)
    @user.exercise_completions.create!(exercise_key: "0.1")

    delete exercise_completion_path("0.1"), as: :turbo_stream

    assert_response :success
    assert_match "Installer Rails et générer un projet vide", response.body
  end

  private

  def sign_in_as(user)
    post "/session_for_test", params: { user_id: user.id }
  end
end
