require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get progress_path

    assert_redirected_to root_path
  end

  test "shows per-part and total progress for the logged-in user" do
    user = User.create!(github_id: "1", username: "alice")
    post "/session_for_test", params: { user_id: user.id }
    user.exercise_completions.create!(exercise_key: "0.1")

    get progress_path

    assert_response :success
    assert_select "body", /1\s*\/\s*80/
  end
end
