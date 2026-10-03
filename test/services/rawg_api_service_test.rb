require "test_helper"
require "minitest/mock"

class RawgApiServiceTest < ActiveSupport::TestCase
  Response = Struct.new(:body) do
    def is_a?(type)
      type == Net::HTTPSuccess || super
    end
  end

  test "search loads developer and description from the game details endpoint" do
    previous_api_key = ENV["RAWG_API_KEY"]
    ENV["RAWG_API_KEY"] = "test-key"
    responses = [
      Response.new({
        results: [{
          id: 123,
          name: "Example Game",
          background_image: "https://media.rawg.io/example.jpg",
          metacritic: 90,
          platforms: [{ platform: { name: "Nintendo Switch" } }],
          genres: [{ name: "RPG" }]
        }]
      }.to_json),
      Response.new({
        developers: [{ name: "Example Studio" }],
        description_raw: "An example story."
      }.to_json)
    ]
    request_paths = []
    http = Object.new
    http.define_singleton_method(:get) do |path|
      request_paths << path
      responses.shift
    end

    Net::HTTP.stub(:start, ->(_host, _port, **_options, &block) { block.call(http) }) do
      @results = RawgApiService.search("Example Game")
    end

    result = @results.fetch(0)
    assert_equal "Example Studio", result[:developer]
    assert_equal "An example story.", result[:description]
    assert_equal ["Switch"], result[:platforms]
    assert_equal ["RPG"], result[:genres]
    assert_not result.key?(:playtime)
    assert_includes request_paths, "/api/games/123?key=test-key"
  ensure
    previous_api_key.nil? ? ENV.delete("RAWG_API_KEY") : ENV["RAWG_API_KEY"] = previous_api_key
  end
end