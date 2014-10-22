require "pry"
require "httparty"
require "nokogiri"
require_relative "player"

class Team
  attr_reader :page, :players

  def initialize(url)
    @page = setup_page(url)
    @players = setup_players
  end

  def woulda
    woulda_team.score.round(2)
  end

  def coulda
    total_score.round(2)
  end

  def shoulda
    shoulda_team.score.round(2)
  end

  def name
    page.at_css(".team-name").text
  end

  private

  def total_score
    players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def bench_score
    bench_players.map(&:points).inject(0) { |sum, points| sum + points }
  end

  def shoulda_team
    @shoulda_team ||= setup_shoulda_team_team
  end

  def woulda_team
    @woulda_team ||= setup_woulda_team_team
  end

  def setup_woulda_team_team
    team = ActiveTeam.new
    team.qb   = lowest_players(position: :qb, number: 1)
    team.rb   = lowest_players(position: :rb, number: 2)
    team.wr   = lowest_players(position: :wr, number: 3)
    team.te   = lowest_players(position: :te, number: 1)
    team.d_st = lowest_players(position: :d_st, number: 1)
    team.k    = lowest_players(position: :k, number: 1)
    team.flex = lowest_flex_player(number: 1, team: team)
    team
  end

  def setup_shoulda_team_team
    team = ActiveTeam.new
    team.qb   = highest_players(position: :qb, number: 1)
    team.rb   = highest_players(position: :rb, number: 2)
    team.wr   = highest_players(position: :wr, number: 3)
    team.te   = highest_players(position: :te, number: 1)
    team.d_st = highest_players(position: :d_st, number: 1)
    team.k    = highest_players(position: :k, number: 1)
    team.flex = highest_flex_player(number: 1, team: team)
    team
  end

  def lowest_flex_player(args)
    number = args.fetch(:number)
    team = args.fetch(:team)

    available_players = team.available_players(grouped_players)

    available_flex_players(available_players).sort_by(&:points).first(number)
  end

  def highest_flex_player(args)
    number = args.fetch(:number)
    team = args.fetch(:team)

    available_players = team.available_players(grouped_players)

    available_flex_players(available_players).sort_by(&:points).last(number)
  end

  def flex_positions
    [:rb, :wr, :te]
  end

  def available_flex_players(available_players)
    flex_positions.inject(Array.new) do |players, position|
      players.push(available_players[position])
    end.flatten
  end

  def grouped_players
    @grouped_players ||= non_zero_players.group_by(&:position)
  end

  def non_zero_players
    players.select { |player| player.non_zero? }
  end

  def lowest_players(args)
    position = args.fetch(:position)
    number = args.fetch(:number)

    grouped_players[position].sort_by(&:points).first(number)
  end

  def highest_players(args)
    position = args.fetch(:position)
    number = args.fetch(:number)

    grouped_players[position].sort_by(&:points).last(number)
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
  attr_accessor :members

  def initialize
    @members = Hash.new
  end

  def score
    members.inject(0) do |sum, (position, players)|
      sum + players.map(&:points).inject(0, :+)
    end
  end

  def qb
    members[:qb]
  end

  def qb=(value)
    self.members[:qb] = value
  end

  def rb
    members[:rb]
  end

  def rb=(value)
    self.members[:rb] = value
  end

  def wr
    members[:wr]
  end

  def wr=(value)
    self.members[:wr] = value
  end

  def te
    members[:te]
  end

  def te=(value)
    self.members[:te] = value
  end

  def flex
    members[:flex]
  end

  def flex=(value)
    self.members[:flex] = value
  end

  def d_st
    members[:d_st]
  end

  def d_st=(value)
    self.members[:d_st] = value
  end

  def k
    members[:k]
  end

  def k=(value)
    self.members[:k] = value
  end

  def available_players(all_players)
    all_players.inject({}) do |available_players, (position, players)|
      available_players[position] = all_players[position] - members[position]
      available_players
    end
  end
end
