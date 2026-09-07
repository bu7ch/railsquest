require "test_helper"

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  test "show 404s for an unknown chapter slug" do
    get part_chapter_path("07-deploiement", "does-not-exist")

    assert_response :not_found
  end
end
