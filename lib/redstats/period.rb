module RedStats
	
  # UTC is time zone of Period.
  class Period

  	PERIODS_FORMATS = { year: 'Y%Y', month: 'M%Y-%m', day: 'D%Y-%m-%d', hour: 'H%Y-%m-%d_%H' }

  	def initialize(period)
      raise "wrong period" unless PERIODS_FORMATS.keys.include?(period)
      @period = period
      @format = PERIODS_FORMATS[period]
  	end

    def minutes?
      @period == :minute
    end

    def beginning(time)
      if minutes?
        time.change(seconds: 0)
      else
        time.send(:"beginning_of_#{@period}")
      end
    end

    # Returns period begining time
    # opts[:ts] = other ts, than current
    # opts[:diff] = diff in units (integer)
    def time(opts = {})
      ts = Time.now.utc 
      ts = opts[:ts] if !opts[:ts].nil?
      ts = beginning(ts)
      ts += opts[:diff].to_i.send(@period) if !opts[:diff].nil?
      ts
    end

    # Returns redis key 
    # opts[:ts] = other ts, than current
    # opts[:diff] = diff in units (integer)
    def key(opts = {})
      time(opts).strftime(@format)
    end


    # Returns time from period redis key 
    def self.time_from_key(ts_key)
      base = "X0001-01-01_00:00:00Z"
      Time.parse(ts_key + base[ts_key.lenght, -1])
    end

    # Returns all periods redis keys
    # opts[:ts] = other ts, than current
    # opts[:diff] = diff in units (integer)
    def self.all_periods_keys(ts = Time.now.utc)
      PERIODS_FORMATS.keys.map{|per| Period.new(per).key(ts: ts) }
    end
  end
end
