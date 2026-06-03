# Station selector tabs — Tier 1 of navigation.
# Renders underline tabs for each station, with the active station highlighted.
#
# Usage:
#   render Nav::StationTabsComponent.new(station_slug: "surf-radio", current_view: "listeners", current_interval: "daily")
class Nav::StationTabsComponent < BaseHtmlComponent
  STATIONS = StationScoped::STATIONS

  def initialize(station_slug:, current_view:, current_interval:)
    @station_slug = station_slug
    @current_view = current_view
    @current_interval = current_interval
  end

  def view_template
    nav(class: "nav-stations") do
      STATIONS.each do |slug, name|
        if slug == @station_slug
          span(class: "nav-tab nav-tab--active") { name }
        else
          a(href: "/#{slug}/#{@current_view}/#{@current_interval}", class: "nav-tab") { name }
        end
      end
    end
  end
end
