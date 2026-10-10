require "test_helper"
require "minitest/mock"

class IgdbApiServiceTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body) do
    def is_a?(type)
      type == Net::HTTPSuccess || super
    end
  end

  test "search queries IGDB once and returns the original summary without translating" do
    previous_env = ENV.slice("IGDB_CLIENT_ID", "DEEPL_API_KEY")
    ENV["IGDB_CLIENT_ID"] = "client-id"
    ENV["DEEPL_API_KEY"] = "deepl-key"

    response = Response.new("200", [{
      name: "Example Game",
      cover: { url: "//images.igdb.com/igdb/image/upload/t_thumb/co123.jpg" },
      platforms: [{ name: "Nintendo Switch" }],
      genres: [{ name: "Role-playing (RPG)" }],
      involved_companies: [{ company: { name: "Example Studio" } }],
      summary: "An English summary.",
      total_rating: 89.6
    }].to_json)
    requests = []
    IgdbApiService.stub(:access_token, "bearer-token") do
      IgdbApiService.stub(:perform_request, ->(_uri, request) {
        requests << request
        response
      }) do
        @results = IgdbApiService.search("Example Game")
      end
    end

    result = @results.fetch(0)
    assert_equal "Example Game", result[:name]
    assert_equal "https://images.igdb.com/igdb/image/upload/t_cover_big/co123.jpg", result[:image]
    assert_equal ["Switch"], result[:platforms]
    assert_equal ["RPG"], result[:genres]
    assert_equal 90, result[:igdb_rating]
    assert_equal "Example Studio", result[:developer]
    assert_equal "An English summary.", result[:description]
    assert_equal "Bearer bearer-token", requests.first["Authorization"]
    assert_includes requests.first.body, 'search "Example Game";'
    assert_includes requests.first.body, "involved_companies.company.name"
    assert_equal 1, requests.length
  ensure
    %w[IGDB_CLIENT_ID DEEPL_API_KEY].each { |key| ENV.delete(key) }
    previous_env.each { |key, value| ENV[key] = value }
  end

  test "search excludes noise categories while retaining expansions and remakes" do
    previous_client_id = ENV["IGDB_CLIENT_ID"]
    ENV["IGDB_CLIENT_ID"] = "client-id"
    games = [
      { name: "Small DLC", category: 1 },
      { name: "Bundle", category: 3 },
      { name: "Pack", category: 13 },
      { name: "Base Game", category: 0 },
      { name: "Large Expansion", category: 2 },
      { name: "Standalone Expansion", category: 4 },
      { name: "Remake", category: 8 },
      { name: "Remaster", category: 9 },
      { name: "Expanded Game", category: 10 },
      { name: "Port", category: 11 }
    ]
    responses = [
      Response.new("200", games.to_json),
      Response.new("200", [
        { name: "Expanded Game", category: 10 },
        { name: "Port", category: 11 }
      ].to_json)
    ]

    IgdbApiService.stub(:access_token, "token") do
      IgdbApiService.stub(:perform_request, ->(*) { responses.shift }) do
        @results = IgdbApiService.search("Example Game")
        @retained_later_categories = IgdbApiService.search("Example Game").map { |game| game[:name] }
      end
    end

    assert_equal [
      "Base Game",
      "Large Expansion",
      "Standalone Expansion",
      "Remake",
      "Remaster"
    ], @results.map { |game| game[:name] }
    assert_equal ["Expanded Game", "Port"], @retained_later_categories
  ensure
    previous_client_id.nil? ? ENV.delete("IGDB_CLIENT_ID") : ENV["IGDB_CLIENT_ID"] = previous_client_id
  end

  test "access token is reused from Rails cache" do
    previous_env = ENV.slice("IGDB_CLIENT_ID", "IGDB_CLIENT_SECRET")
    ENV["IGDB_CLIENT_ID"] = "client-id"
    ENV["IGDB_CLIENT_SECRET"] = "client-secret"
    Rails.cache.delete(IgdbApiService::TOKEN_CACHE_KEY)
    request_count = 0
    cache = ActiveSupport::Cache::MemoryStore.new
    http = Object.new
    http.define_singleton_method(:request) do |_request|
      request_count += 1
      Response.new("200", { access_token: "cached-token", expires_in: 3600 }.to_json)
    end

    Rails.stub(:cache, cache) do
      Net::HTTP.stub(:start, ->(_host, _port, **_options, &block) { block.call(http) }) do
        assert_equal "cached-token", IgdbApiService.access_token
        assert_equal "cached-token", IgdbApiService.access_token
      end
    end
    assert_equal 1, request_count
  ensure
    Rails.cache.delete(IgdbApiService::TOKEN_CACHE_KEY)
    %w[IGDB_CLIENT_ID IGDB_CLIENT_SECRET].each { |key| ENV.delete(key) }
    previous_env.each { |key, value| ENV[key] = value }
  end

  test "translation failure falls back to original summary" do
    previous_api_key = ENV["DEEPL_API_KEY"]
    ENV["DEEPL_API_KEY"] = "deepl-key"
    failure = ->(_host, _port, **_options, &_block) { raise IOError, "connection failed" }

    Net::HTTP.stub(:start, failure) do
      assert_equal "Original summary", IgdbApiService.translate_text("Original summary")
    end
  ensure
    previous_api_key.nil? ? ENV.delete("DEEPL_API_KEY") : ENV["DEEPL_API_KEY"] = previous_api_key
  end
end