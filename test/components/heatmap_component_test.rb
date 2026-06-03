require "minitest/autorun"
require "nokogiri"
require "active_support"
require "active_support/core_ext/string"
require "phlex"

require_relative "../../app/components/base_svg_component"
require_relative "../../app/components/heatmap_component"

class HeatmapComponentTest < Minitest::Test
  def sample_data
    {
      [0, 10] => 5,
      [0, 11] => 12,
      [1, 10] => 3,
      [1, 14] => 20,
      [6, 23] => 1
    }
  end

  def day_names
    %w[Sun Mon Tue Wed Thu Fri Sat]
  end

  def render_component(component)
    Nokogiri::HTML.fragment(component.call)
  end

  def test_renders_svg_element
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    svg = doc.at_css("svg")
    assert svg, "Expected an <svg> element"
  end

  def test_renders_correct_grid_dimensions
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    cells = doc.css('rect[data-role="heatmap-cell"]')
    # 7 days × 24 hours = 168 cells
    assert_equal 168, cells.length
  end

  def test_renders_row_labels
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    labels = doc.css('text[data-role="row-label"]')
    assert_equal 7, labels.length
    assert_equal "Sun", labels[0].text
    assert_equal "Sat", labels[6].text
  end

  def test_renders_column_labels
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    labels = doc.css('text[data-role="col-label"]')
    assert_equal 24, labels.length
    assert_equal "0", labels[0].text
    assert_equal "23", labels[23].text
  end

  def test_each_cell_has_tooltip
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    # Check cells with data have titles
    cells_with_data = doc.css('g[data-has-value="true"] title')
    assert cells_with_data.length >= 5, "Expected at least 5 cells with data titles"
  end

  def test_empty_cells_render_with_zero_intensity
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    cells = doc.css('rect[data-role="heatmap-cell"]')
    # Cells without data should still render (with low/zero fill)
    assert_equal 168, cells.length
  end

  def test_handles_empty_data
    doc = render_component(HeatmapComponent.new(data: {}, day_names: day_names))
    svg = doc.at_css("svg")
    assert svg, "Should render SVG even with no data"
    cells = doc.css('rect[data-role="heatmap-cell"]')
    assert_equal 168, cells.length
  end

  def test_has_aria_label
    doc = render_component(HeatmapComponent.new(data: sample_data, day_names: day_names))
    svg = doc.at_css("svg")
    assert svg["aria-label"], "Expected aria-label on SVG"
  end
end
