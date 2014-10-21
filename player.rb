require "nokogiri"

class Player
  def initialize(element)
    @element = element
  end

  def points
    element.css(".appliedPoints")[2].text.to_f
  end

  def bench?
    position == "Bench"
  end

  def position
    element.at_css(".playerSlot").text
  end

  private

  attr_reader :element
end
