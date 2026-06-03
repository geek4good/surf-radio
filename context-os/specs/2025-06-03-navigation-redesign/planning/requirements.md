# Navigation Redesign — Requirements

## Answers from stakeholder

1. **Station selector**: Light underline tabs (not segmented control)
2. **Default landing**: Root redirects to Surf Radio → Listeners → Daily
3. **Patterns placement**: Merged into Listeners interval row (Daily | Weekly | Monthly | Patterns)
4. **URL structure**: Scoped path segments (`/surf-radio/listeners/daily`)
5. **Station switch**: Preserves current view + interval
6. **Intervals**: Same everywhere — Daily | Weekly | Monthly | Patterns for both Listeners and Songs
7. **Visual design**: I design it, matching current aesthetic
8. **Mobile**: Simple text links, no hamburger

## Implications of unified intervals (#6)

Songs currently uses different periods (This Week, This Month, Last Month, This Year, All Time). With unified nav, Songs adapts:

| Interval | Listeners shows | Songs shows |
|----------|----------------|-------------|
| Daily | Hourly listeners for one day | Songs played today |
| Weekly | Daily averages for one week | Songs played this week |
| Monthly | Daily averages for one month | Songs played this month |
| Patterns | Heatmap, day-of-week, weekend vs weekday | — (not applicable) |

This is a breaking change to the Songs view — the old period options are replaced. Songs does not get a Patterns view.

## Navigation hierarchy

```
┌─────────────────────────────────────────┐
│  Surf Radio  |  Talay FM               │  ← Station (underline tabs)
├─────────────────────────────────────────┤
│  Listeners  |  Songs                   │  ← Data view (underline tabs)
├─────────────────────────────────────────┤
│  Daily  |  Weekly  |  Monthly  |  Patterns │  ← Interval (lighter links)
└─────────────────────────────────────────┘
```

All three rows visible on every page. Active item clearly indicated in each row.

## URLs

```
/surf-radio/listeners/daily       # root redirects here
/surf-radio/listeners/weekly
/surf-radio/listeners/monthly
/surf-radio/listeners/patterns
/surf-radio/songs/daily
/surf-radio/songs/weekly
/surf-radio/songs/monthly
/surf-radio/songs/patterns
/talay-fm/listeners/daily
/talay-fm/listeners/weekly
...etc
```

Switching station: `/surf-radio/listeners/weekly` → `/talay-fm/listeners/weekly` (same view + interval).

## Station as URL context

Every page is scoped to one station. The controller reads station from the URL segment, not from a query param. This means:

- `params[:station]` → `"surf-radio"` or `"talay-fm"`
- Controller maps slug to station name: `"surf-radio"` → `"Surf Radio"`, `"talay-fm"` → `"Talay FM"`
- All data queries are filtered to that single station
- No more showing two stations on one page

## Phlex migration

All views converted to Phlex components as part of this redesign. Layouts remain ERB.

New component tree:
- `Nav::StationTabsComponent` — station selector
- `Nav::ViewTabsComponent` — Listeners | Songs
- `Nav::IntervalTabsComponent` — Daily | Weekly | Monthly | Patterns
- `ChartCardComponent` — card wrapper (reused everywhere)
- `DataTableComponent` — reusable data table
- `Listeners::DailyView` — replaces `stats/index.html.erb`
- `Listeners::WeeklyView` — replaces `stats/weekly.html.erb`
- `Listeners::MonthlyView` — replaces `stats/monthly.html.erb`
- `Listeners::PatternsView` — replaces `stats/patterns.html.erb`
- `Songs::DailyView`, `Songs::WeeklyView`, `Songs::MonthlyView` — new
