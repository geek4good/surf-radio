require "test_helper"

class ListenersControllerTest < ActionDispatch::IntegrationTest
  # ── Route resolution ──

  test "root resolves to listeners#show with defaults" do
    assert_recognizes(
      { controller: "listeners", action: "show", station: "surf-radio", interval: "daily" },
      "/"
    )
  end

  test "listeners route resolves to listeners#show" do
    assert_recognizes(
      { controller: "listeners", action: "show", station: "surf-radio", interval: "daily" },
      "/surf-radio/listeners/daily"
    )
  end

  test "listeners patterns route resolves to listeners#show" do
    assert_recognizes(
      { controller: "listeners", action: "show", station: "talay-fm", interval: "patterns" },
      "/talay-fm/listeners/patterns"
    )
  end

  # ── Daily view ──

  test "daily renders successfully" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
  end

  test "daily accepts date param" do
    get listeners_path(station: "surf-radio", interval: "daily", date: "2025-12-25")
    assert_response :success
  end

  test "daily with invalid date falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "daily", date: "not-a-date")
    assert_response :success
    # Should fall back to yesterday and still render
  end

  test "daily with impossible date falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "daily", date: "2025-13-45")
    assert_response :success
  end

  test "daily shows title with station name" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_includes response.body, "Surf Radio"
  end

  test "daily shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "daily")
    assert_response :success
    assert_includes response.body, "No stats recorded yet"
  end

  # ── Weekly view ──

  test "weekly renders successfully" do
    get listeners_path(station: "surf-radio", interval: "weekly")
    assert_response :success
  end

  test "weekly accepts week param" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "2025-W52")
    assert_response :success
  end

  test "weekly with invalid week format falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "not-a-week")
    assert_response :success
  end

  test "weekly with nonsensical week falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "weekly", week: "9999-W99")
    assert_response :success
  end

  test "weekly shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "weekly")
    assert_response :success
    assert_includes response.body, "No stats recorded for this week"
  end

  # ── Monthly view ──

  test "monthly renders successfully" do
    get listeners_path(station: "surf-radio", interval: "monthly")
    assert_response :success
  end

  test "monthly accepts month param" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-12")
    assert_response :success
  end

  test "monthly with invalid month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "abc-def")
    assert_response :success
  end

  test "monthly with out-of-range month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-99")
    assert_response :success
  end

  test "monthly shows month label" do
    get listeners_path(station: "surf-radio", interval: "monthly", month: "2025-12")
    assert_response :success
    assert_includes response.body, "December 2025"
  end

  test "monthly shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "monthly")
    assert_response :success
    assert_includes response.body, "No stats recorded for this month"
  end

  # ── Patterns view ──

  test "patterns renders successfully" do
    get listeners_path(station: "surf-radio", interval: "patterns")
    assert_response :success
  end

  test "patterns accepts month param" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-12")
    assert_response :success
  end

  test "patterns defaults to previous month" do
    get listeners_path(station: "surf-radio", interval: "patterns")
    assert_response :success
    expected_month = (Date.current - 1.month).beginning_of_month.strftime("%B %Y")
    assert_includes response.body, expected_month
  end

  test "patterns shows month navigation" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "2025-12")
    assert_response :success
    assert_includes response.body, "December 2025"
    assert_includes response.body, "2025-11"
    assert_includes response.body, "2026-01"
  end

  test "patterns hides next link when month is current or future" do
    current_month = Date.current.strftime("%Y-%m")
    get listeners_path(station: "surf-radio", interval: "patterns", month: current_month)
    assert_response :success
    next_month = Date.current.next_month.strftime("%Y-%m")
    assert_not_includes response.body, "month=#{next_month}"
  end

  test "patterns with invalid month falls back gracefully" do
    get listeners_path(station: "surf-radio", interval: "patterns", month: "garbage")
    assert_response :success
  end

  test "patterns shows no-data message when no stats" do
    get listeners_path(station: "talay-fm", interval: "patterns")
    assert_response :success
    assert_includes response.body, "No stats recorded"
  end

  # ── Station scoping ──

  test "invalid station slug redirects to default station" do
    get "/nonexistent-station/listeners/daily"
    assert_redirected_to "/surf-radio/listeners/daily"
  end

  test "talay-fm station renders successfully" do
    get listeners_path(station: "talay-fm", interval: "daily")
    assert_response :success
    assert_includes response.body, "Talay FM"
  end

  test "surf-radio station renders successfully" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Surf Radio"
  end

  # ── Interval validation ──

  test "invalid interval falls back to daily" do
    get listeners_path(station: "surf-radio", interval: "garbage")
    assert_response :success
    # Should render daily view without error
  end

  test "convenience redirect from /listeners to /listeners/daily" do
    get "/surf-radio/listeners"
    assert_redirected_to "/surf-radio/listeners/daily"
  end

  # ── Navigation components present ──

  test "daily view includes station tabs" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Talay FM"
  end

  test "daily view includes interval tabs" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    # Interval tabs render as nav-interval elements
    assert_includes response.body, "Daily"
  end

  test "daily view includes view tabs" do
    get listeners_path(station: "surf-radio", interval: "daily")
    assert_response :success
    assert_includes response.body, "Songs"
  end
end
