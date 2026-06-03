# Data view tabs — Tier 2 of navigation.
# Renders Listeners | Songs tabs.
#
# Usage:
#   render Nav::ViewTabsComponent.new(station_slug: "surf-radio", current_view: "listeners", current_interval: "daily")
class Nav::ViewTabsComponent < BaseHtmlComponent
  VIEWS = [
    ["listeners", "Listeners"],
    ["songs", "Songs"]
  ].freeze

  def initialize(station_slug:, current_view:, current_interval:)
    @station_slug = station_slug
    @current_view = current_view
    @current_interval = current_interval
  end

  def view_template
    nav(class: "nav-views") do
      VIEWS.each do |slug, name|
        if slug == @current_view
          span(class: "nav-tab nav-tab--active") { name }
        else
          a(href: "/#{@station_slug}/#{slug}/#{@current_interval}", class: "nav-tab") { name }
        end
      end
    end
  end
end
