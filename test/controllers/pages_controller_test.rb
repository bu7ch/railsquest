require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home lists all existing parts with their status" do
    get root_path

    assert_response :success
    assert_select "body", /Authentification/
    assert_select "body", /Déploiement/
  end
end
