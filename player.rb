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
    position_text.match(/(QB|RB|WR|TE|D\/ST|K)/).captures.first
  end

  def present?
    element.at_css(".playertableData").text != "--"
  end

  private

  attr_reader :element

  def position_text
    element.at_css(".playertablePlayerName").text.split(" ").last 
  end
end
