# Row of summary stat cards.
# Renders a flex row of cards, each with a title and key-value pairs.
#
# Usage:
#   render SummaryCardsComponent.new(cards: [
#     { title: "Weekend", stats: { "Avg" => "12", "Peak" => "30" } },
#     { title: "Weekday", stats: { "Avg" => "8", "Peak" => "25" } },
#   ])
class SummaryCardsComponent < BaseHtmlComponent
  def initialize(cards:)
    @cards = cards
  end

  def view_template
    div(class: "summary-cards") do
      @cards.each do |card|
        div(class: "summary-card") do
          h3 { card[:title] }
          card[:stats].each do |key, value|
            p { "#{key}: #{value}" }
          end
        end
      end
    end
  end
end
