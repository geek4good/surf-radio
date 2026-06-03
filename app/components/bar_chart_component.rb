# SVG bar chart component using Phlex.
# Renders a stacked bar chart (average + peak) with Y-axis grid lines,
# X-axis labels, native SVG tooltips, and a legend.
#
# Usage:
#   render BarChartComponent.new(stats: [["0", 10, 25, 12], ["1", 15, 30, 18]])
#
# stats: Array of [label, average, maximum, median]
class BarChartComponent < BaseSvgComponent
  CHART_WIDTH = 800
  CHART_HEIGHT = 350
  PADDING_LEFT = 48
  PADDING_RIGHT = 16
  PADDING_TOP = 16
  PADDING_BOTTOM = 48
  BAR_GAP = 4

  def initialize(stats:, width: CHART_WIDTH, height: CHART_HEIGHT, dark_mode: false)
    super(dark_mode: dark_mode)
    @stats = stats
    @width = width
    @height = height
  end

  def view_template
    c = colors

    plot_left = PADDING_LEFT
    plot_right = @width - PADDING_RIGHT
    plot_top = PADDING_TOP
    plot_bottom = @height - PADDING_BOTTOM
    plot_width = plot_right - plot_left
    plot_height = plot_bottom - plot_top

    max_value = @stats.map { |s| s[2] }.max || 0
    grid_lines, = compute_grid(max_value)
    y_max = grid_lines.last || 1

    svg(
      width: @width,
      height: @height,
      viewBox: "0 0 #{@width} #{@height}",
      role: "img",
      "aria-label": "Bar chart showing #{@stats.length} data points",
      xmlns: "http://www.w3.org/2000/svg",
      style: "max-width: 100%; height: auto;"
    ) do
      desc { "Bar chart with #{@stats.length} bars showing average and peak values" }

      # Y-axis grid lines
      grid_lines.reverse_each.with_index do |value, _i|
        y = plot_bottom - (value.to_f / y_max * plot_height)
        line(
          x1: plot_left, y1: y,
          x2: plot_right, y2: y,
          stroke: c[:grid_line], stroke_width: 1
        )
        text(
          x: plot_left - 8, y: y + 4,
          "text-anchor": "end",
          fill: c[:text],
          "font-size": "12",
          "data-role": "grid-label"
        ) { format_number(value) }
      end

      # Zero line
      line(
        x1: plot_left, y1: plot_bottom,
        x2: plot_right, y2: plot_bottom,
        stroke: c[:grid_line], stroke_width: 1
      )

      # Bars
      if @stats.any?
        bar_count = @stats.length
        total_gaps = (bar_count - 1) * BAR_GAP
        bar_width = ((plot_width - total_gaps) / bar_count).floor
        # Clamp bar width for readability
        bar_width = [bar_width, 40].min

        # Center the bars if they don't fill the width
        total_bars_width = bar_count * bar_width + (bar_count - 1) * BAR_GAP
        offset_x = plot_left + (plot_width - total_bars_width) / 2

        g("data-role": "bars") do
          @stats.each_with_index do |(label, avg, peak, _median), i|
            x = offset_x + i * (bar_width + BAR_GAP)

            avg_height = (avg.to_f / y_max * plot_height).round(2)
            peak_height = ((peak - avg).to_f / y_max * plot_height).round(2)
            total_height = avg_height + peak_height

            y_avg = plot_bottom - total_height
            y_peak = plot_bottom - total_height + peak_height

            g("data-role": "bar-group") do
              title { "#{label} — Avg: #{avg}, Peak: #{peak}" }

              # Peak bar (on top)
              if peak_height > 0
                rect(
                  x: x, y: y_peak,
                  width: bar_width, height: [peak_height, 0.5].max,
                  fill: c[:peak],
                  rx: 2
                )
              end

              # Average bar (below peak)
              if avg_height > 0
                rect(
                  x: x, y: y_avg + peak_height,
                  width: bar_width, height: [avg_height, 0.5].max,
                  fill: c[:avg]
                )
              end

              # X-axis label
              text(
                x: x + bar_width / 2, y: plot_bottom + 20,
                "text-anchor": "middle",
                fill: c[:text],
                "font-size": "11",
                "data-role": "x-label"
              ) { label }
            end
          end
        end
      end

      # Legend
      g("data-role": "legend", transform: "translate(#{plot_left + plot_width / 2 - 80}, #{plot_bottom + 38})") do
        rect(x: 0, y: -8, width: 10, height: 10, fill: c[:avg], rx: 2)
        text(x: 16, y: 0, fill: c[:text], "font-size": "13") { "Average" }

        rect(x: 90, y: -8, width: 10, height: 10, fill: c[:peak], rx: 2)
        text(x: 106, y: 0, fill: c[:text], "font-size": "13") { "Peak" }
      end
    end
  end
end
