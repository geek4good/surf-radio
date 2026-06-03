class ListenersController < ApplicationController
  include StationScoped

  VALID_INTERVALS = LISTENER_INTERVALS

  def show
    case @interval
    when "daily" then show_daily
    when "weekly" then show_weekly
    when "monthly" then show_monthly
    when "patterns" then show_patterns
    else show_daily
    end
  end

  private

  def show_daily
    @date = begin
      params[:date] ? Date.parse(params[:date]) : Date.current - 1.day
    rescue Date::Error, ArgumentError
      Date.current - 1.day
    end

    day_start = Time.zone.local(@date.year, @date.month, @date.day)
    day_end = day_start + 1.day

    scope = station_scope(Stat).hourly
    stats = hourly_stats(scope, day_start, day_end)
    date_label = @date.strftime("%A, %-d %B %Y")

    prev_date = (@date - 1.day).strftime("%Y-%m-%d")
    next_date = (@date + 1.day) <= Date.current ? @date.next_day.strftime("%Y-%m-%d") : nil

    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "daily", date: prev_date),
      label: "#{date_label} (ICT, UTC+7)",
      next_href: next_date ? listeners_path(station: @station_slug, interval: "daily", date: next_date) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "daily",
      title: @station_name,
      date_nav: date_nav
    ) { |v|
      if stats.any?
        v.render ChartCardComponent.new(title: @station_name, subtitle: "Listeners per hour") do
          v.render BarChartComponent.new(stats: stats)
        end
      else
        v.p { "No stats recorded yet." }
      end
    }
    render view
  end

  def show_weekly
    @week_start = begin
      if params[:week].present? && params[:week].match?(/\A\d{4}-W\d{1,2}\z/)
        year, week_num = params[:week].split("-W").map(&:to_i)
        Date.commercial(year, week_num, 1)
      end
    rescue Date::Error, ArgumentError
      nil
    end
    @week_start ||= (Date.current - 1.week).beginning_of_week(:monday)

    @week_end = @week_start + 7.days
    week_label = "#{@week_start.strftime("%-d %b")} – #{(@week_end - 1.day).strftime("%-d %b %Y")}"

    week_start_time = Time.zone.local(@week_start.year, @week_start.month, @week_start.day)
    week_end_time = Time.zone.local(@week_end.year, @week_end.month, @week_end.day)

    scope = station_scope(Stat).daily
    stats = fetch_daily_stats(scope, week_start_time, week_end_time, @week_start)
    summary = daily_period_summary(scope, week_start_time, week_end_time)

    next_week_start = @week_start + 1.week
    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "weekly", week: (@week_start - 1.week).strftime("%G-W%V")),
      label: "Week of #{week_label} (ICT, UTC+7)",
      next_href: next_week_start <= Date.current ? listeners_path(station: @station_slug, interval: "weekly", week: next_week_start.strftime("%G-W%V")) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "weekly",
      title: @station_name,
      date_nav: date_nav
    ) { |v|
      if stats.any? { |s| s[1] > 0 }
        v.render ChartCardComponent.new(title: @station_name, subtitle: "Daily averages") do
          v.render BarChartComponent.new(stats: stats)
        end
        if summary
          v.render SummaryRowComponent.new(summary: summary)
        end
      else
        v.p { "No stats recorded for this week." }
      end
    }
    render view
  end

  def show_monthly
    @month_start = begin
      if params[:month].present? && params[:month].match?(/\A\d{4}-\d{2}\z/)
        year, month = params[:month].split("-").map(&:to_i)
        Date.new(year, month, 1)
      end
    rescue Date::Error, ArgumentError
      nil
    end
    @month_start ||= (Date.current - 1.month).beginning_of_month

    @month_end = @month_start.next_month
    month_label = @month_start.strftime("%B %Y")

    month_start_time = Time.zone.local(@month_start.year, @month_start.month, @month_start.day)
    month_end_time = Time.zone.local(@month_end.year, @month_end.month, @month_end.day)

    scope = station_scope(Stat).daily
    stats = fetch_daily_stats(scope, month_start_time, month_end_time, @month_start)
    summary = daily_period_summary(scope, month_start_time, month_end_time)

    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "monthly", month: (@month_start - 1.month).strftime("%Y-%m")),
      label: "#{month_label} (ICT, UTC+7)",
      next_href: @month_end <= Date.current ? listeners_path(station: @station_slug, interval: "monthly", month: @month_end.strftime("%Y-%m")) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "monthly",
      title: @station_name,
      date_nav: date_nav
    ) { |v|
      if stats.any? { |s| s[1] > 0 }
        v.render ChartCardComponent.new(title: @station_name, subtitle: "Daily averages") do
          v.render BarChartComponent.new(stats: stats)
        end
        if summary
          v.render SummaryRowComponent.new(summary: summary)
        end
      else
        v.p { "No stats recorded for this month." }
      end
    }
    render view
  end

  def show_patterns
    @month_start = begin
      if params[:month].present? && params[:month].match?(/\A\d{4}-\d{2}\z/)
        year, month = params[:month].split("-").map(&:to_i)
        Date.new(year, month, 1)
      end
    rescue Date::Error, ArgumentError
      nil
    end
    @month_start ||= (Date.current - 1.month).beginning_of_month

    @month_end = @month_start.next_month
    prev_month = (@month_start - 1.month).strftime("%Y-%m")
    next_month = @month_end.strftime("%Y-%m")
    month_label = @month_start.strftime("%B %Y")

    local_ts = %("from" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Bangkok')
    from_time = @month_start.to_time(:utc).iso8601
    to_time = @month_end.to_time(:utc).iso8601
    time_filter = Stat.sanitize_sql(["WHERE \"from\" >= :from AND \"from\" < :to AND station = :station", { from: from_time, to: to_time, station: @station_name }])

    dow_averages = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        EXTRACT(DOW FROM #{local_ts}) AS dow,
        ROUND(AVG(average))::int AS avg_listeners,
        ROUND(AVG(maximum))::int AS avg_peak
      FROM stats
      #{time_filter}
      GROUP BY EXTRACT(DOW FROM #{local_ts})
      ORDER BY dow
    SQL

    heatmap_data_raw = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        EXTRACT(DOW FROM #{local_ts}) AS dow,
        EXTRACT(HOUR FROM #{local_ts}) AS hour,
        ROUND(AVG(average))::int AS avg_listeners
      FROM stats
      #{time_filter}
      GROUP BY EXTRACT(DOW FROM #{local_ts}), EXTRACT(HOUR FROM #{local_ts})
      ORDER BY dow, hour
    SQL

    weekend_weekday = Stat.connection.select_all(<<~SQL).to_a
      SELECT
        CASE WHEN EXTRACT(DOW FROM #{local_ts}) IN (0, 6) THEN 'weekend' ELSE 'weekday' END AS period,
        ROUND(AVG(average))::int AS avg_listeners,
        ROUND(AVG(maximum))::int AS avg_peak
      FROM stats
      #{time_filter}
      GROUP BY period
      ORDER BY period DESC
    SQL

    day_names = %w[Sun Mon Tue Wed Thu Fri Sat]

    # Build heatmap data hash
    heatmap_data = {}
    heatmap_data_raw.each do |row|
      heatmap_data[[row["dow"].to_i, row["hour"].to_i]] = row["avg_listeners"].to_i
    end

    # Build day-of-week chart data
    dow_chart = dow_averages.map do |row|
      [day_names[row["dow"].to_i], row["avg_listeners"].to_i, row["avg_peak"].to_i, row["avg_listeners"].to_i]
    end

    # Build weekend/weekday cards
    ww_cards = weekend_weekday.map do |row|
      {
        title: row["period"].capitalize,
        stats: {
          "Avg" => row["avg_listeners"].to_s,
          "Peak" => row["avg_peak"].to_s
        }
      }
    end

    date_nav = {
      prev_href: listeners_path(station: @station_slug, interval: "patterns", month: prev_month),
      label: month_label,
      next_href: @month_end <= Date.current ? listeners_path(station: @station_slug, interval: "patterns", month: next_month) : nil
    }

    view = Listeners::ShowView.new(
      station_slug: @station_slug,
      interval: "patterns",
      title: "Listener Patterns — #{@station_name}",
      date_nav: date_nav
    ) { |v|
      if dow_averages.any?
        v.render ChartCardComponent.new(title: "Day-of-Week Averages", subtitle: "Average listeners by day") do
          v.render BarChartComponent.new(stats: dow_chart)
        end
      end

      if heatmap_data_raw.any?
        v.render ChartCardComponent.new(title: "Hour × Day Heatmap", subtitle: "Average listeners (darker = more)") do
          v.render HeatmapComponent.new(data: heatmap_data, day_names: day_names)
        end
      end

      if weekend_weekday.any?
        v.render ChartCardComponent.new(title: "Weekend vs Weekday") do
          v.render SummaryCardsComponent.new(cards: ww_cards)
        end
      end

      if dow_averages.empty? && heatmap_data_raw.empty?
        v.p { "No stats recorded for #{month_label}." }
      end
    }
    render view
  end

  def hourly_stats(scope, day_start, day_end)
    scope
      .where(from: day_start...day_end)
      .order(:from)
      .map do |stat|
        local_hour = stat.from.in_time_zone.strftime("%-k")
        [local_hour, stat.average || 0, stat.maximum || 0, stat.median || 0]
      end
  end

  def fetch_daily_stats(scope, period_start, period_end, date_start)
    rows = scope
      .where(from: period_start...period_end)
      .index_by { |s| s.from.in_time_zone.to_date }

    num_days = ((period_end - period_start) / 1.day).to_i
    days = (date_start...(date_start + num_days.days)).to_a

    days.map do |date|
      stat = rows[date]
      if stat
        [date.strftime("%-d"), stat.average, stat.maximum, stat.median]
      else
        [date.strftime("%-d"), 0, 0, 0]
      end
    end
  end

  def daily_period_summary(scope, period_start, period_end)
    stats = scope.where(from: period_start...period_end)
    return nil if stats.empty?

    {
      avg: (stats.average(:average) || 0).round,
      peak: stats.maximum(:maximum) || 0,
      median: (stats.average(:median) || 0).round,
      hours: stats.sum(:snapshot_count)
    }
  end

end
