require_relative 'helper'

setup do 
  RedStats.namespace = "test"
end

test 't_slash' do

  assert RedStats.t_slash("downloads") == "downloads/"
  assert RedStats.t_slash("downloads/") == "downloads/"
  assert RedStats.t_slash("downloads/foo") == "downloads/foo/"
  assert RedStats.t_slash("downloads/foo/") == "downloads/foo/"

end

test 'simple count sum' do
  ts = Time.parse("2015-11-07_19:23:00Z")

  100.times{
    RedStats.stat("downloads", nil, ts)
  }

  assert RedStats.get_stats("downloads", :year, ts, 0) == [["Y2015", [100, 0]]]

end

test 'sum and count on many levels' do
  ts = Time.parse("2015-11-07_19:23:00Z")

  RedStats.stat("downloads", 2, ts)
  RedStats.stat("downloads/foo", 3, ts)
  RedStats.stat("downloads/foo/bar", 2, ts)
  RedStats.stat("downloads/bar", 3, ts)
  RedStats.stat("downloads/bar/baz", 5, ts)

  assert RedStats.get_stats("downloads", :year, ts, 0) == [["Y2015", [5, 15]]]
  assert RedStats.get_stats("downloads/foo", :year, ts, 0) == [["Y2015", [2, 5]]]
  assert RedStats.get_stats("downloads/foo/bar", :year, ts, 0) == [["Y2015", [1, 2]]]
  assert RedStats.get_stats("downloads/bar", :year, ts, 0) == [["Y2015", [2, 8]]]
  assert RedStats.get_stats("downloads/bar/baz", :year, ts, 0) == [["Y2015", [1, 5]]]
  assert RedStats.get_stats("downloads/baz", :year, ts, 0) == [["Y2015", [0, 0]]]



end

test 'count and sum in all periods should be equal' do

  ts = Time.parse("2015-11-07_19:23:00Z")

  100.times{
    RedStats.stat("downloads", 2, ts)
  }

  assert RedStats.get_stats("downloads", :year, ts, 0)  == [["Y2015", [100, 200]]]
  assert RedStats.get_stats("downloads", :month, ts, 0) == [["M2015-11", [100, 200]]]
  assert RedStats.get_stats("downloads", :day, ts, 0)   == [["D2015-11-07", [100, 200]]]
  assert RedStats.get_stats("downloads", :hour, ts, 0)  == [["H2015-11-07_19", [100, 200]]]

end

test 'count for long hours' do
  ts = Time.parse("2015-11-07_19:23:00Z")

  100.times{|x|
    RedStats.stat("downloads", 2, ts - (3600 * x))
  }

  assert RedStats.get_stats("downloads", :year, ts, -4)   == [["Y2011", [0, 0]], ["Y2012", [0, 0]], ["Y2013", [0, 0]], ["Y2014", [0, 0]], ["Y2015", [100, 200]]]
  assert RedStats.get_stats("downloads", :month, ts, -4)  == [["M2015-07", [0, 0]], ["M2015-08", [0, 0]], ["M2015-09", [0, 0]], ["M2015-10", [0, 0]], ["M2015-11", [100, 200]]]
  assert RedStats.get_stats("downloads", :day, ts, -4)    == [["D2015-11-03", [8, 16]], ["D2015-11-04", [24, 48]], ["D2015-11-05", [24, 48]], ["D2015-11-06", [24, 48]], ["D2015-11-07", [20, 40]]]
  assert RedStats.get_stats("downloads", :hour, ts, -4)   == [["H2015-11-07_15", [1, 2]], ["H2015-11-07_16", [1, 2]], ["H2015-11-07_17", [1, 2]], ["H2015-11-07_18", [1, 2]], ["H2015-11-07_19", [1, 2]]]
  assert RedStats.get_stats("downloads", :hour, ts, -100).map{|k,v| v[0]}.reduce(:+) == 100
  assert RedStats.get_stats("downloads", :hour, ts, -100).map{|k,v| v[1]}.reduce(:+) == 200

end

test 'get childs' do 
  ts = Time.parse("2015-11-07_19:23:00Z")

  RedStats.stat("downloads", 2, ts)
  RedStats.stat("downloads/foo", 3, ts)
  RedStats.stat("downloads/foo/bar", 2, ts)
  RedStats.stat("downloads/bar", 3, ts)
  RedStats.stat("downloads/bar/baz", 5, ts)

  assert RedStats.get_childs("downloads") == ["foo", "bar"]
  assert RedStats.get_childs("downloads/foo") ==["bar"]
  assert RedStats.get_childs("downloads/bar") == ["baz"]
  assert RedStats.get_childs("downloads/bar/baz") == []

end