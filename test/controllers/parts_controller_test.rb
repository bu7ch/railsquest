require "test_helper"

class PartsControllerTest < ActionDispatch::IntegrationTest
  test "show renders a coming-soon part with no chapters" do
    get part_path("07-deploiement")

    assert_response :success
    assert_select "body", /Déploiement/
    assert_select "body", /à venir|coming soon|bientôt/i
  end

  test "show 404s for an unknown part slug" do
    get part_path("99-does-not-exist")

    assert_response :not_found
  end
end
