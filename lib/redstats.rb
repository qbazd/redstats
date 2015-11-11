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

    ts = ts.utc
    ts_now = Time.now.utc
    key_path = t_slash(key_path)
    prds = RedStats::Period.all_periods_keys(ts)
    key_levels = []
    each_key_sublevel(key_path){|key_level| key_levels << key_level}

    redis.pipelined do |pipe|
      key_levels.each{|key_level|
        #set dir and touch
        pipe.hset( self.basekey["stats"][key_level], "ts", ts_now.to_i )
        pipe.sadd( self.basekey["dirs"][t_slash(File.dirname(key_level))], File.basename(key_level) )

        prds.each{|field|
          pipe.hincrby( self.basekey["stats"][key_level], "count"+field, 1 )
          pipe.hincrby( self.basekey["stats"][key_level], "sum"+field, val ) unless val.nil?
        }
      }
    end

    true
  end


  def self.stat_w_minmax(key_path, val, ts = Time.now.utc)

    ts = ts.utc
    ts_now = Time.now.utc
    key_path = t_slash(key_path)

    prds = RedStats::Period.all_periods_keys(ts)
    key_levels = []
    each_key_sublevel(key_path){|key_level| key_levels << key_level}

    loop do         
      break if redis.watch( key_levels.map{|kl| self.basekey["stats"][kl] } ) do |redis_watch|

        min_max = redis_watch.pipelined do |pipe|
          key_levels.each{|key_level|
            prds.each{|field| 
              pipe.hmget( self.basekey["stats"][key_level], "min"+field, "max"+field) 
            }
          }

        end

        min_max = min_max.each_slice(prds.length).to_a.map{|ar| ar.map{|min,max| [min.nil? || val < min.to_i ? val : min, max.nil? || val > max.to_i ? val : max ] }}
        redis_watch.multi do |redis_multi|
          [key_levels, *(min_max.transpose)].transpose.each{|key_level, *kl_prds|
            #ap [key_level,kl_prds]
            redis_multi.hset( self.basekey["stats"][key_level], "ts", ts_now.to_i )
            redis_multi.sadd( self.basekey["dirs"][t_slash(File.dirname(key_level))], File.basename(key_level) )

            [prds, kl_prds].transpose.each{|field,minmax|
              min, max = minmax
              redis_multi.hmset( self.basekey["stats"][key_level], "min"+field, min, "max"+field, max )
              redis_multi.hincrby( self.basekey["stats"][key_level], "count"+field, 1 )
              redis_multi.hincrby( self.basekey["stats"][key_level], "sum"+field, val ) unless val.nil?

            }
          }
        end

      end
    end
    true
  end        


  #Get stats of all childs of given key_path
  def self.get_childs(key_path, period, ts = Time.now.utc)

    ts = ts.utc

    key_path = t_slash(key_path)

    prd_field = RedStats::Period.new(period).key(ts: ts)

    childs = redis.smembers(self.basekey["dirs"][key_path])

    ret = redis.pipelined do |pipe| 
        childs.each{|child| 
            child_path = t_slash(key_path + "#{child}")
            pipe.hget(self.basekey["stats"][child_path], "mtime")
            pipe.hmget( self.basekey["stats"][child_path], "count"+prd_field, "sum"+prd_field, "min"+prd_field, "max"+prd_field )
        }
    end

    ret = ret.each_slice(2).to_a
    
    ret.map!{|_ts, ret_prd| 
      #ap [_ts, ret_prds]
      ret_prd = [ret_prd.map{|e| e.nil? ? nil : e.to_i }].map{|count,sum,min,max| { count: count, sum:sum , min: min, max: max} }.first

      {
        period_key: prd_field,
        mtime: (_ts.nil? ? nil : Time.at(_ts.to_i).utc),
        stats: ret_prd}
      }

    Hash[[childs, ret].transpose]
  end


  #Get time series of key_path for given period
  def self.get_stats(key_path , period, ts, units_diff )

    key_path = t_slash(key_path)
    period = Period.new(period) unless period.is_a? Period
    range = (0..units_diff) 
    range = (units_diff..0) if units_diff < 0
    ts_keys = range.to_a.map{|u| period.key(ts: ts, diff: u)}

    ret = redis.pipelined do |pipe|
      ts_keys.each{|field|
        pipe.hmget(self.basekey["stats"][key_path], "count"+field, "sum"+field, "min"+field, "max"+field)
      }
    end

    ret = ret.map{|arr| arr.map{|e| e.nil? ? nil : e.to_i } }.
            map{|count,sum,min,max| { count: count, sum:sum , min: min, max: max} } 

    Hash[ [ts_keys,ret].transpose ]
  end

#  def self.purge_period(key_path, priod, leave_units)
#    #scan
#  end

end
