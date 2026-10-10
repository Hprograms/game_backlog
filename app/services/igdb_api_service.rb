require "net/http"
require "json"
require "stringio"

class IgdbApiService
  TOKEN_CACHE_KEY = "igdb_api_access_token".freeze
  TOKEN_CACHE_TTL = 50.days
  SEARCHABLE_GAME_CATEGORIES = [0, 2, 4, 8, 9, 10, 11].freeze

  PLATFORM_NAMES = {
    "Nintendo Switch" => "Switch",
    "PlayStation 5" => "PS5",
    "PlayStation 4" => "PS4",
    "Xbox One" => "Xbox",
    "Xbox Series X|S" => "Xbox",
    "PC (Microsoft Windows)" => "PC"
  }.freeze

  GENRE_NAMES = {
    "Action" => "アクション",
    "Adventure" => "アドベンチャー",
    "Role-playing (RPG)" => "RPG",
    "RPG" => "RPG",
    "Simulator" => "シミュレーション",
    "Sport" => "スポーツ"
  }.freeze

  def self.search(query)
    client_id = ENV["IGDB_CLIENT_ID"]
    token = access_token
    return [] if client_id.blank? || token.blank?

    request = Net::HTTP::Post.new(URI("https://api.igdb.com/v4/games"))
    request["Client-ID"] = client_id
    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "text/plain"
    request.body = apicalypse_query(query)

    response = perform_request(request.uri, request)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("IGDB API Error [#{response.code}]: #{response.body}")
      return []
    end

    # API側で完璧にフィルタリングされるため、Ruby側のreject処理は全削除してOK
    JSON.parse(response.body).first(5).map { |game| format_game(game) }
  rescue StandardError => e
    Rails.logger.error("IGDB API Error: #{e.message}")
    []
  end

  def self.attach_cover_image(game, image_url)
    uri = URI.parse(image_url)
    return unless uri.is_a?(URI::HTTPS) && uri.host == "images.igdb.com"

    response = perform_request(uri, Net::HTTP::Get.new(uri))
    return unless response.is_a?(Net::HTTPSuccess)

    content_type = response["content-type"].to_s.split(";").first
    return unless content_type.start_with?("image/") && response.body.bytesize <= 15.megabytes

    filename = File.basename(uri.path).presence || "igdb-game-cover.jpg"
    game.image.attach(io: StringIO.new(response.body), filename: filename, content_type: content_type)
  rescue StandardError => e
    Rails.logger.error("IGDB cover image error: #{e.message}")
  end

  def self.access_token
    client_id = ENV["IGDB_CLIENT_ID"]
    client_secret = ENV["IGDB_CLIENT_SECRET"]
    return if client_id.blank? || client_secret.blank?

    Rails.cache.fetch(TOKEN_CACHE_KEY, expires_in: TOKEN_CACHE_TTL) do
      request_access_token(client_id, client_secret)
    end&.dig(:access_token)
  rescue StandardError => e
    Rails.logger.error("Twitch OAuth Error: #{e.message}")
    nil
  end

  def self.apicalypse_query(query)
    escaped_query = query.to_s.gsub(/[\\"]/) { |character| "\\#{character}" }
    %(search "#{escaped_query}"; fields name, cover.url, platforms.name, genres.name, involved_companies.company.name, summary, total_rating, game_type.*; where game_type = (0,2,4,8,9,10,11) & version_parent = null; limit 15;)
  end

  def self.translate_text(text)
    api_key = ENV["DEEPL_API_KEY"]
    return text if text.blank? || api_key.blank?

    uri = URI("https://api-free.deepl.com/v2/translate")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "DeepL-Auth-Key #{api_key}"
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.set_form_data(text: text, target_lang: "JA")
    response = perform_request(uri, request)
    return text unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).dig("translations", 0, "text").presence || text
  rescue StandardError => e
    Rails.logger.error("DeepL API Error: #{e.message}")
    text
  end

  def self.format_game(game)
    cover_url = game.dig("cover", "url")
    cover_url = cover_url&.sub(%r{\A//}, "https://")&.sub("t_thumb", "t_cover_big")
    summary = game["summary"].to_s
    developer = Array(game["involved_companies"]).filter_map { |entry| entry.dig("company", "name") }.first

    {
      name: game["name"],
      image: cover_url,
      platforms: Array(game["platforms"]).filter_map { |entry| PLATFORM_NAMES[entry["name"]] }.uniq,
      genres: Array(game["genres"]).filter_map { |entry| GENRE_NAMES[entry["name"]] }.uniq,
      igdb_rating: game["total_rating"]&.round,
      developer: developer,
      description: summary
    }
  end

  def self.request_access_token(client_id, client_secret)
    uri = URI("https://id.twitch.tv/oauth2/token")
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret
    )
    response = perform_request(uri, request)
    raise "Twitch OAuth returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    expires_in = body.fetch("expires_in").to_i
    { access_token: body.fetch("access_token"), expires_at: Time.current + [expires_in - 60, 1].max.seconds }
  end
  private_class_method :request_access_token

  def self.perform_request(uri, request)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
  end
  private_class_method :perform_request
end