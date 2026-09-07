require "test_helper"

class ExerciseCompletionTest < ActiveSupport::TestCase
  test "a user cannot complete the same exercise twice" do
    user = User.create!(github_id: "1", username: "alice")
    user.exercise_completions.create!(exercise_key: "0.1")

    duplicate = user.exercise_completions.build(exercise_key: "0.1")

    assert_not duplicate.valid?
  end

  test "User#completed? reflects whether an exercise has been marked done" do
    user = User.create!(github_id: "2", username: "bob")

    assert_not user.completed?("0.1")

    user.exercise_completions.create!(exercise_key: "0.1")

    assert user.completed?("0.1")
  end
end
