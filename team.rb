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
    score = 0
    score += lowest_players_scores(position: "QB", number: 1)
    score += lowest_players_scores(position: "RB", number: 2)
    score += lowest_players_scores(position: "WR", number: 3)
    score += lowest_players_scores(position: "TE", number: 1)
    score += lowest_players_scores(position: "D/ST", number: 1)
    score += lowest_players_scores(position: "K", number: 1)
  end

  private

  def grouped_players
    @grouped_players ||= non_zero_players.group_by(&:position)
  end

  def non_zero_players
    players.select { |player| player.non_zero? }
  end

  def lowest_players_scores(args)
    players = lowest_players(args)
    players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def lowest_players(args)
    position = args.fetch(:position)
    number = args.fetch(:number)

    grouped_players[position].sort_by(&:points).first(number)
  end

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

