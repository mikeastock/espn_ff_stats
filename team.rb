require "httparty"
require "nokogiri"
require_relative "player"

class Team
  attr_reader :page, :players

  def initialize(url)
    @page = setup_page(url)
    @players = setup_players
  end

  def total_points
    players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def bench_points
    bench_players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def woulda
  end

  def grouped_players
    @grouped_players ||= players.group_by(&:position)
  end

  private

  def bench_players
    players.select { |player| player.bench? }
  end

  def setup_page(url)
    Nokogiri::HTML(HTTParty.get(url))
  end

  def setup_players
    all_players.select { |player| player.present? }
  end

  def all_players
    player_elements.map { |element| Player.new(element) }
  end

  def player_elements
    page.css(".pncPlayerRow")
  end
end

