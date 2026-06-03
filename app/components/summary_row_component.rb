# Renders a summary row with Avg, Peak, Hours stats.
# Used below bar charts in weekly and monthly views.
#
# Usage:
#   render SummaryRowComponent.new(summary: { avg: 12, peak: 30, hours: 168 })
class SummaryRowComponent < BaseHtmlComponent
  def initialize(summary:)
    @summary = summary
  end

  def view_template
    div(class: "summary-row") do
      span { "Avg: #{@summary[:avg]}" }
      span { "Peak: #{@summary[:peak]}" }
      span { "Hours: #{@summary[:hours]}" }
    end
  end
end
