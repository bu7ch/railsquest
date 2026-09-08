require "test_helper"
require "tmpdir"
require "fileutils"

class PartsControllerTest < ActionDispatch::IntegrationTest
  test "show renders a coming-soon part with no chapters" do
    Dir.mktmpdir do |dir|
      root = Pathname.new(dir)
      part_dir = root.join("08-a-venir")
      FileUtils.mkdir_p(part_dir)
      File.write(part_dir.join("part.yml"), { "number" => 8, "title" => "À venir", "status" => "coming_soon" }.to_yaml)

      original_default_root = ContentLoader.method(:default_root)
      ContentLoader.define_singleton_method(:default_root) { root }
      begin
        get part_path("08-a-venir")
      ensure
        ContentLoader.define_singleton_method(:default_root, original_default_root)
      end
    end

    assert_response :success
    assert_select "body", /À venir/
    assert_select "body", /à venir|coming soon|bientôt/i
  end

  test "show 404s for an unknown part slug" do
    get part_path("99-does-not-exist")

    assert_response :not_found
  end
end
