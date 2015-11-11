require_relative 'helper'

setup do 
end

test 'minute' do
  time = Time.parse("2015-03-05 08:23:00Z")
  per = RedStats::Period.new(:minute)
  assert per.beginning(time) == Time.parse("2015-03-05 08:23:00Z")
  assert per.time(ts: time, diff: 0) == Time.parse("2015-03-05 08:23:00Z")
  assert per.time(ts: time, diff: -8) == Time.parse("2015-03-05 08:15:00Z")
  assert per.key(ts: time, diff: -8) == "M2015-03-05_08:15"
end


test 'hour' do
  time = Time.parse("2015-03-05 08:23:00Z")
  per = RedStats::Period.new(:hour)
  assert per.beginning(time) == Time.parse("2015-03-05 08:00:00Z")
  assert per.time(ts: time, diff: 0) == Time.parse("2015-03-05 08:00:00Z")
  assert per.time(ts: time, diff: -8) == Time.parse("2015-03-05 00:00:00Z")
  assert per.key(ts: time, diff: -8) == "H2015-03-05_00"
end

test 'day' do

  time = Time.parse("2015-03-05 08:23:00Z")
  per = RedStats::Period.new(:day)
  assert per.beginning(time) == Time.parse("2015-03-05 00:00:00Z")
  assert per.time(ts: time, diff: 0) == Time.parse("2015-03-05 00:00:00Z")
  assert per.time(ts: time, diff: -8) == Time.parse("2015-02-25 00:00:00Z")
  assert per.key(ts: time, diff: -8) == "d2015-02-25"
end

test 'month' do

  time = Time.parse("2015-03-05 08:23:00Z")
  per = RedStats::Period.new(:month)
  assert per.beginning(time) == Time.parse("2015-03-01 00:00:00Z")
  assert per.time(ts: time, diff: 0) == Time.parse("2015-03-01 00:00:00Z")
  assert per.time(ts: time, diff: -3) == Time.parse("2014-12-01 00:00:00Z")
  assert per.key(ts: time, diff: -8) == "m2014-07"
end

test 'year' do

  time = Time.parse("2015-03-05 08:23:00Z")
  per = RedStats::Period.new(:year)
  assert per.beginning(time) == Time.parse("2015-01-01 00:00:00Z")
  assert per.time(ts: time, diff: 0) == Time.parse("2015-01-01 00:00:00Z")
  assert per.time(ts: time, diff: -3) == Time.parse("2012-01-01 00:00:00Z")
  assert  per.key(ts: time, diff: -8) == "Y2007"

end

test 'all keys' do

  time = Time.parse("2015-03-05 08:23:00Z")
  assert RedStats::Period.all_periods_keys(time) == ["Y2015", "m2015-03", "d2015-03-05", "H2015-03-05_08", "M2015-03-05_08:23"]

end
