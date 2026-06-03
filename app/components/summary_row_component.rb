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
      span { "Avg: "; strong { @summary[:avg].to_s } }
      span { "Peak: "; strong { @summary[:peak].to_s } }
      span { "Hours: "; strong { @summary[:hours].to_s } }
    end
  end
end
