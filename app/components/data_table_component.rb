# Reusable data table component.
# Renders a <table class="data-table"> with headers and rows.
#
# Usage:
#   render DataTableComponent.new(
#     headers: ["#", "Title", "Artist", "Plays"],
#     rows: [[1, "Song", "Artist", 42], ...]
#   )
class DataTableComponent < BaseHtmlComponent
  def initialize(headers:, rows:)
    @headers = headers
    @rows = rows
  end

  def view_template
    table(class: "data-table") do
      thead do
        tr do
          @headers.each do |h|
            th { h }
          end
        end
      end
      tbody do
        @rows.each do |row|
          tr do
            row.each do |cell|
              td { cell.to_s }
            end
          end
        end
      end
    end
  end
end
