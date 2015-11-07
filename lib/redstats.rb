require 'redis'
require 'nido'
require 'active_support/time'

require 'redstats/version'
require 'redstats/period'


module RedStats

    def self.namespace=(ns)
      @namespace = ns
    end

    def self.namespace
      @namespace ||= "redstats"
    end

    def self.redis=(arg)
      if arg.is_a? Redis
        @redis = arg
      else
        @redis = Redis.new(arg)
      end
    end

    # Returns the Redis connection
    def self.redis
      @redis ||= Redis.new
    end

	def self.basekey
		Nido.new(self.namespace)
	end

	def self.t_slash(str)
		str.gsub(/\/+$/,'') + "/"
	end

	def self.each_key_sublevel(key)
		keys = key.gsub(/\/*$/,'').split("/")
		x = keys.count - 1
		while(x >= 0) do 
			yield(keys[0..x].join("/") + "/")
			x -= 1
		end
	end

	def self.stat(key_path, val = nil, ts = Time.now.utc)

		key_path = t_slash(key_path)

		prds = RedStats::Period.all_periods_keys(ts)

		redis.pipelined do 
			each_key_sublevel(key_path){|key_level|	prds.each{|field|
				#p [ self.basekey["stats"][key_level], "c"+field, "s"+field]
				redis.sadd( self.basekey["dirs"][File.dirname(key_level)], File.basename(key_level) )
				redis.hincrby( self.basekey["stats"][key_level], "c"+field, 1 )
				redis.hincrby( self.basekey["stats"][key_level], "s"+field, val ) unless val.nil?
			}}
		end

		true
	end

	def self.get_childs(key_path)
		redis.smembers(self.basekey["dirs"][key_path])
	end

	#get stats

	def self.get_stats(key_path , period, ts, units_diff )

		key_path = t_slash(key_path)
		period = Period.new(period) unless period.is_a? Period
		range = (0..units_diff) 
		range = (units_diff..0) if units_diff < 0
		ts_keys = range.to_a.map{|u| period.key(ts: ts, diff: u)}

		ret = redis.pipelined do
			ts_keys.each{|field|
				redis.hmget(self.basekey["stats"][key_path], "c"+field, "s"+field)
			}
		end

		ret.map!{|h,s| [h.nil? ? 0 : h.to_i , s.nil? ? 0 : s.to_i ]}

		[ts_keys,ret].transpose
	end

end