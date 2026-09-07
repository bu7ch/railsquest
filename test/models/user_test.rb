require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "find_or_create_from_omniauth creates a new user on first login" do
    auth = OmniAuth::AuthHash.new(
      uid: "12345",
      info: { nickname: "octocat", image: "https://example.org/avatar.png" }
    )

    assert_difference "User.count", 1 do
      user = User.find_or_create_from_omniauth(auth)

      assert_equal "12345", user.github_id
      assert_equal "octocat", user.username
      assert_equal "https://example.org/avatar.png", user.avatar_url
    end
  end

  test "find_or_create_from_omniauth returns the existing user on repeat login" do
    auth = OmniAuth::AuthHash.new(uid: "12345", info: { nickname: "octocat", image: "https://example.org/a.png" })
    first = User.find_or_create_from_omniauth(auth)

    assert_no_difference "User.count" do
      second = User.find_or_create_from_omniauth(auth)
      assert_equal first.id, second.id
    end
  end
end
