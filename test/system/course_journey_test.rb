require "application_system_test_case"

class CourseJourneyTest < ApplicationSystemTestCase
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      uid: "42", info: { nickname: "learner", image: "https://example.org/learner.png" }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "a visitor logs in, reads a chapter, checks an exercise, and sees progress update" do
    visit root_path
    click_on "Se connecter avec GitHub"

    assert_text "learner"

    click_on "Partie 0"
    click_on "MVC et convention over configuration"

    assert_text "Convention over configuration en pratique"

    within "#exercise_0-1" do
      click_on "Marquer comme fait"
    end

    within "#exercise_0-1" do
      assert_text "Décocher"
    end

    click_on "Ma progression"

    assert_text "1 / 60"
  end
end
