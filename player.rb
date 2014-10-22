require "nokogiri"

class Player
  def initialize(element)
    @element = element
  end

  def points
    element.css(".appliedPoints")[2].text.to_f
  end

  def bench?
    element.at_css(".playerSlot").text == "Bench"
  end

  def position
    position_text.
      match(/(QB|RB|WR|TE|D\/ST|K)/).
      captures.
      first.
      downcase.
      gsub("/", "_").
      to_sym
  end

  def present?
    element.at_css(".playertableData").text != "--"
  end

  def non_zero?
    if position == :d_st || position == :k
      true
    else
      points != 0
    end
  end

  def name
    player_name_element.split(",").first
  end

  private

  attr_reader :element

  def position_text
    player_name_element.split(" ").last 
  end

  def player_name_element
    element.at_css(".playertablePlayerName").text
  end
end
