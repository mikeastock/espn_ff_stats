require "pry"
require "httparty"
require "nokogiri"
require_relative "player"

class Team
  attr_reader :page, :players
  attr_accessor :available_players

  def initialize(url)
    @page = setup_page(url)
    @players = setup_players
    @available_players = grouped_players
  end

  def total_points
    players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def bench_points
    bench_players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def woulda_team
    @woulda_team ||= setup_woulda_team_team
  end

  def setup_woulda_team_team
    team = ActiveTeam.new
    team.qb = lowest_players(position: :qb, number: 1)
    team.rb = lowest_players(position: :rb, number: 2)
    team.wr = lowest_players(position: :wr, number: 3)
    team.te = lowest_players(position: :te, number: 1)
    team.d_st = lowest_players(position: :d_st, number: 1)
    team.k = lowest_players(position: :k, number: 1)
    team
  end

  def coulda
    total_points
  end

  def name
    page.at_css(".team-name").text
  end

  # private
  
  def calculate_woulda
    score = 0
    score += lowest_players_scores(position: :qb, number: 1)
    score += lowest_players_scores(position: :rb, number: 2)
    score += lowest_players_scores(position: :wr, number: 3)
    score += lowest_players_scores(position: :te, number: 1)
    score += lowest_players_scores(position: :d_st, number: 1)
    score += lowest_players_scores(position: :k, number: 1)
    score += lowest_flex_score(number: 1)
  end

  def lowest_flex_score(args)
    number = args.fetch(:number)

    player = available_flex_players.sort_by(&:points).first
    player.points
  end

  def flex_positions
    [:rb, :wr, :te]
  end

  def available_flex_players
    @available_flex_players ||= flex_positions.inject(Array.new) do |players, position|
      players.push(available_players[position])
    end.flatten
  end

  def grouped_players
    @grouped_players ||= non_zero_players.group_by(&:position)
  end

  def non_zero_players
    players.select { |player| player.non_zero? }
  end

  def lowest_players_scores(args)
    players = lowest_players(args)

    update_available_players(args.merge(players: players))
    players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def update_available_players(args)
    players = args.fetch(:players)
    position = args.fetch(:position)
    
    new_available_players = available_players[position] - players
    self.available_players[position] = new_available_players
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

class ActiveTeam
  attr_accessor :players

  def initialize
    @players = setup_players
  end

  def qb
    players[:qb]
  end

  def qb=(value)
    self.players[:qb] = value
  end

  def rb
    players[:rb]
  end

  def rb=(value)
    self.players[:rb] + value
  end

  def wr
    players[:wr]
  end

  def wr=(value)
    self.players[:wr] + value
  end

  def te
    players[:te]
  end

  def te=(value)
    self.players[:te] = value
  end

  def flex
    players[:flex]
  end

  def flex=(value)
    self.players[:flex] = value
  end

  def k
    players[:k]
  end

  def k=(value)
    self.players[:k] = value
  end

  def setup_players
    {
      qb: "",
      rb: [],
      wr: [],
      te: "",
      flex: "",
      d_st: "",
      k: ""
    }
  end
end
