require_relative 'helper'

setup do 
  Timecop.freeze(Time.local(2013, 01, 01, 01, 01))
  RedStats.namespace = "test"
end

test 't_slash' do

  assert RedStats.t_slash("") == "/"
  assert RedStats.t_slash("/downloads") == "/downloads/"
  assert RedStats.t_slash("downloads/") == "/downloads/"
  assert RedStats.t_slash("/downloads/foo") == "/downloads/foo/"
  assert RedStats.t_slash("downloads/foo/") == "/downloads/foo/"

end

test 'each_levels' do
  paths = []
  RedStats.each_key_sublevel("downloads/foo/downloads/foo/"){|x|  paths << x }

  assert paths == ["/downloads/foo/downloads/foo/", "/downloads/foo/downloads/", "/downloads/foo/", "/downloads/"]

end


test 'simple count' do
  ts = Time.parse("2015-11-07_19:23:00Z")

  100.times{
    RedStats.stat("downloads", nil, ts)
  }

  assert RedStats.get_stats("downloads", :year, ts, 0)["Y2015"][:count] == 100

end

test 'sum and count on many levels' do
  ts = Time.parse("2015-11-07_19:23:00Z")

  RedStats.stat("downloads", 2, ts)
  RedStats.stat("downloads/foo", 3, ts)
  RedStats.stat("downloads/foo/bar", 2, ts)
  RedStats.stat("downloads/bar", 3, ts)
  RedStats.stat("downloads/bar/baz", 5, ts)

  stats = RedStats.get_stats("downloads", :year, ts, 0)["Y2015"]

  assert  stats[:count] == 5
  assert  stats[:sum] == 15

end

test 'count and sum in all periods should be equal' do

  ts = Time.parse("2015-11-07_19:23:00Z")

  100.times{
    RedStats.stat("downloads", 2, ts)
  }
  
  {year: "Y2015", month: "M2015-11", day: "D2015-11-07", hour:"H2015-11-07_19"}.each{|prd, prd_key| 
    stats = RedStats.get_stats("downloads", prd, ts, 0)[prd_key]
    assert stats[:count] == 100
    assert stats[:sum] == 200
  }

end

test 'count for long hours' do

  ts = Time.parse("2015-11-07_19:23:00Z")

  100.times{|x|
    RedStats.stat("downloads", 2, ts - (3600 * x))
  }
  
  stats = RedStats.get_stats("downloads", :year, ts, -4).to_a.last[1]
  assert [stats[:count], stats[:sum]] == [100,200]

  stats = RedStats.get_stats("downloads", :month, ts, -4).to_a.last[1]
  assert [stats[:count], stats[:sum]] == [100,200]

end

test 'get childs' do 
  ts1 = Time.now 
  ts2 = ts1.dup.utc 

  RedStats.stat("downloads", 2, ts1)
  RedStats.stat("downloads/foo", 3, ts2)
  RedStats.stat("downloads/foo/bar", 2, ts1)
  RedStats.stat("downloads/bar", 3, ts2)
  RedStats.stat("downloads/bar/baz", 5, ts1)

  childs = RedStats.get_childs("downloads", :year,ts1) 
  assert childs.keys == %w[foo bar]

end


test 'UTC vs local' do 
  ts1 = Time.now
  ts2 = Time.now.utc 

  RedStats.stat("downloads", 2, ts1)
  RedStats.stat("downloads/foo", 3, ts2)
  RedStats.stat("downloads/foo/bar", 2, ts1)
  RedStats.stat("downloads/bar", 3, ts2)
  RedStats.stat("downloads/bar/baz", 5, ts1)

  stats = RedStats.get_stats("downloads", :hour, ts1, 0).to_a.last[1]
  assert [stats[:count], stats[:sum]] == [5,15]

  stats = RedStats.get_stats("downloads", :hour, ts2, 0).to_a.last[1]
  assert [stats[:count], stats[:sum]] == [5,15]

end

test 'min max' do 

  ts = Time.parse("2015-11-07_19:23:00Z")

  RedStats.stat_w_minmax("downloads", 2, ts)
  RedStats.stat_w_minmax("downloads/foo", 3, ts)
  RedStats.stat_w_minmax("downloads/foo/bar", -4, ts)
  RedStats.stat_w_minmax("downloads/bar", 3, ts)
  RedStats.stat_w_minmax("downloads/bar/baz", 5, ts)

  stats = RedStats.get_stats("downloads", :year, ts, 0).to_a.first[1]

  assert [stats[:count],stats[:sum],stats[:min], stats[:max]] == [5, 9, -4, 5]

end

test 'get childs values' do 

  ts = Time.parse("2015-11-07_19:23:00Z")

  RedStats.stat_w_minmax("downloads", 2, ts)
  RedStats.stat_w_minmax("downloads/foo", 3, ts)
  RedStats.stat_w_minmax("downloads/foo/bar", -4, ts)
  RedStats.stat_w_minmax("downloads/bar", 3, ts)
  RedStats.stat_w_minmax("downloads/bar/baz", 5, ts)

  stats = RedStats.get_childs("downloads", :hour, ts)["bar"]

  assert [stats[:mtime],stats[:stats][:count],stats[:stats][:sum],stats[:stats][:min], stats[:stats][:max]] == [Time.now, 2, 8, 3, 5]

end
