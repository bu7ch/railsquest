require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      uid: "99999", info: { nickname: "hubot", image: "https://example.org/hubot.png" }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "create logs the user in and redirects home" do
    get "/auth/github/callback"

    assert_redirected_to root_path
    follow_redirect!
    assert_select "body", /hubot/
  end

  test "destroy logs the user out" do
    get "/auth/github/callback"
    delete "/logout"

    follow_redirect!
    # button_to renders a <form><button>, not an <a> tag, so this asserts on
    # the button element rather than the anchor the brief's test literally
    # names.
    assert_select "button", "Se connecter avec GitHub"
  end
end
