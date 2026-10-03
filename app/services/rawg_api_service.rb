# app/services/rawg_api_service.rb
require 'net/http'
require 'json'
require 'stringio'

class RawgApiService
  PLATFORM_NAMES = {
    'Nintendo Switch' => 'Switch',
    'PlayStation 5' => 'PS5',
    'PlayStation 4' => 'PS4',
    'Xbox One' => 'Xbox',
    'Xbox Series S/X' => 'Xbox',
    'PC' => 'PC'
  }.freeze

  GENRE_NAMES = {
    'Action' => 'アクション',
    'Adventure' => 'アドベンチャー',
    'RPG' => 'RPG',
    'Simulation' => 'シミュレーション',
    'Sports' => 'スポーツ'
  }.freeze

  def self.search(query)
    api_key = ENV['RAWG_API_KEY']
    return [] if api_key.blank?

    uri = URI('https://api.rawg.io/api/games')
    uri.query = URI.encode_www_form(key: api_key, search: query, page_size: 5)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end
    return [] unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('results', []).first(5).map do |game|
      {
        name: game["name"],
        image: game["background_image"],
        metacritic: game["metacritic"],
        playtime: game["playtime"],
        platforms: Array(game.dig('platforms')).filter_map { |entry| PLATFORM_NAMES[entry.dig('platform', 'name')] }.uniq,
        genres: Array(game['genres']).filter_map { |genre| GENRE_NAMES[genre['name']] }.uniq
      }
    end

  rescue StandardError => e
    Rails.logger.error("RAWG API Error: #{e.message}")
    []
  end

  def self.attach_image(game, image_url)
    uri = URI.parse(image_url)
    allowed_host = uri.host == 'rawg.io' || uri.host&.end_with?('.rawg.io')
    return unless uri.is_a?(URI::HTTPS) && allowed_host

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 8) do |http|
      http.get(uri.request_uri)
    end
    return unless response.is_a?(Net::HTTPSuccess)

    content_type = response['content-type'].to_s.split(';').first
    return unless content_type.start_with?('image/') && response.body.bytesize <= 15.megabytes

    filename = File.basename(uri.path).presence || 'rawg-game-image.jpg'
    game.image.attach(io: StringIO.new(response.body), filename: filename, content_type: content_type)
  rescue StandardError => e
    Rails.logger.error("RAWG image error: #{e.message}")
  end
end