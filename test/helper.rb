begin
  require "ruby-debug"
rescue LoadError
end

require "cutest"

def silence_warnings
  original_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = original_verbose
end unless defined?(silence_warnings)

$VERBOSE = true

require 'timecop'
require 'awesome_print'

require_relative "../lib/redstats"

raise "no DEV_REDIS_URL env var set, DEV_REDIS_URL=redis://127.0.0.1:6379/13 , will be flushed!" if ENV['DEV_REDIS_URL'].nil? or ENV['DEV_REDIS_URL'].empty?

RedStats.redis = Redis.new(url: ENV['DEV_REDIS_URL'])

prepare do
  RedStats.redis.flushdb
end
