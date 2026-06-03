# Navigation Redesign + Full Phlex Migration — Spec

## Goal

Restructure the app so every page is scoped to a single radio station (Surf Radio or Talay FM) with a clear two-row navigation. Migrate all remaining ERB views to Phlex components.

## User Stories

1. As a station operator, I want to see data for **one station at a time** so I can focus without visual clutter from the other station.
2. As a station operator, I want to **switch stations** with one click and land on the same view/interval, so I can compare without re-navigating.
3. As a station operator, I want to always see **where I am** in the navigation with zero ambiguity.
4. As a station operator, I want Songs to have a **consistent navigation structure** (Daily/Weekly/Monthly) matching the Listeners intervals.

## Navigation Design

### Two-row navigation (always visible)

Row 1 merges station + data view on one line. Row 2 is the interval selector.

```
Row 1:  Surf Radio  |  Talay FM        Listeners  |  Songs
Row 2:  Daily  |  Weekly  |  Monthly  |  Patterns
```

Songs omits Patterns, so its Row 2 shows only: `Daily | Weekly | Monthly`.

On mobile, Row 1 wraps naturally — stations cluster left, data views may wrap to a second line if needed.

### Visual treatment

**Row 1 (Station + Data View)**: Single underline spanning the full width. Left side has station tabs, right side has data view tabs. Active station gets bold text + bottom border in `--color-text`. Active data view gets lighter weight bottom border. Inactive items are `--color-muted`. The two groups are visually separated by spacing (stations cluster left, data views cluster right).

**Row 2 (Interval)**: Lighter weight links (not full tabs). Active item gets `font-weight: 600` and `--color-text`, inactive items are `--color-muted`. No border — just text emphasis.

The page title (`h1`) appears below both nav rows.

### Mobile behavior

All rows wrap naturally. Text links are touch-friendly. No hamburger menu.

## URL Structure

```
/:station/listeners/:interval    # interval = daily|weekly|monthly|patterns
/:station/songs/:interval        # interval = daily|weekly|monthly
```

Station slugs: `surf-radio`, `talay-fm`.

### Routes

```ruby
root "listeners#daily"  # redirects to /surf-radio/listeners/daily

scope "/:station" do
  get "listeners/:interval", to: "listeners#show", as: :listeners
  get "songs/:interval", to: "songs#show", as: :songs
  get "listeners", to: redirect("/%{station}/listeners/daily")
  get "songs", to: redirect("/%{station}/songs/daily")
end
```

### Controller changes

- **`ListenersController`** (renamed from `StatsController`): single `show` action. Reads `params[:station]` and `params[:interval]`. Renders the appropriate view based on interval. Only queries data for the selected station.
- **`SongsController`**: single `show` action. Same pattern — reads station + interval. Adapts existing period logic to daily/weekly/monthly. Songs does not have a Patterns view.

A concern module validates `params[:station]` against allowed values and provides `@station_name` and `@station_slug`.

## View Changes

### Listeners (per station, per interval)

| Interval | What shows | Data source |
|----------|-----------|-------------|
| Daily | Hourly bar chart for one day (date picker: prev/next day) | Existing `hourly_stats` |
| Weekly | Daily bar chart for one week (prev/next week) | Existing `fetch_daily_stats` |
| Monthly | Daily bar chart for one month (prev/next month) | Existing `fetch_daily_stats` |
| Patterns | Heatmap, day-of-week bar chart, weekend vs weekday | Existing patterns queries, single station |

Station Comparison table is removed — it compared two stations, contradicting single-station design.

### Songs (per station, per interval)

| Interval | What shows | Data source |
|----------|-----------|-------------|
| Daily | Songs played today: content breakdown + tables | Existing logic, filtered to one day |
| Weekly | Songs played this week | Existing logic, filtered to current week |
| Monthly | Songs played this month | Existing logic, filtered to current month |

## Phlex Components

### Navigation components
- `Nav::StationTabsComponent` — station underline tabs with active state
- `Nav::ViewTabsComponent` — Listeners | Songs tabs
- `Nav::IntervalTabsComponent` — interval links (Daily | Weekly | Monthly | Patterns for Listeners; Daily | Weekly | Monthly for Songs)

### Layout components
- `ChartCardComponent` — `<section class="chart-card">` wrapper
- `DataTableComponent` — reusable `<table class="data-table">`
- `SummaryCardsComponent` — row of summary stat cards

### Page components
- `Listeners::ShowView` — delegates to interval-specific content
- `Listeners::DailyView` / `WeeklyView` / `MonthlyView` — bar chart + summary
- `Listeners::PatternsView` — heatmap + day-of-week chart + weekend/weekday cards
- `Songs::ShowView` — delegates to interval-specific content
- `Songs::DailyView` / `WeeklyView` / `MonthlyView` — content breakdown + tables

### Existing (keep as-is)
- `BaseSvgComponent` — shared SVG base
- `BarChartComponent` — SVG bar chart
- `HeatmapComponent` — SVG heatmap

## Existing Code to Leverage

- **`StatsController`** logic → move to `ListenersController` or shared concern
- **`SongsController`** query logic → adapt to station-scoped + interval-based
- **`Stat` model** scopes — already have `surf_radio`, `talay_fm`
- **`SongPlay` model** — already has station scoping via `for_station`
- **Phlex SVG components** — already built, reused as-is
- **CSS variables and card styles** — already defined, extend with nav styles

## Out of Scope

- Station comparison feature (removed)
- Songs Patterns view (not applicable)
- Authentication / authorization
- API endpoints
- Mailer views (staying ERB)
- Layout `application.html.erb` (staying ERB)
- Dark mode changes (existing variable system continues)
- Date/time navigation (prev/next day/week) — keep existing behavior, adapt URLs
