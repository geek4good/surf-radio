require "test_helper"

class LegacyRoutesTest < ActionDispatch::IntegrationTest
  test "legacy stats/index redirects to surf-radio listeners daily" do
    get "/stats/index"
    assert_redirected_to "/surf-radio/listeners/daily"
  end

  test "legacy stats/weekly redirects to surf-radio listeners weekly" do
    get "/stats/weekly"
    assert_redirected_to "/surf-radio/listeners/weekly"
  end

  test "legacy stats/monthly redirects to surf-radio listeners monthly" do
    get "/stats/monthly"
    assert_redirected_to "/surf-radio/listeners/monthly"
  end

  test "legacy stats/patterns redirects to surf-radio listeners patterns" do
    get "/stats/patterns"
    assert_redirected_to "/surf-radio/listeners/patterns"
  end

  test "legacy songs redirects to surf-radio songs daily" do
    get "/songs"
    assert_redirected_to "/surf-radio/songs/daily"
  end

  test "legacy stats routes respond with 301 redirects" do
    get "/stats/index"
    assert_response :redirect
  end
end
