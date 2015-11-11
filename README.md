RedStats
========

RedStats is a library to track statistics using Redis database.

Description
-----------

Library to track statistics. Library tracks hourly/daily/monthly/yearly hits and sums so avg also.
Library sums for every level in key_path: eg. "downloads/user/ip/action/file".
Adds in: downlods, downloads/user, downloads/user/ip, downloads/user/ip/action, downloads/user/ip/action/file

Inspired by Von gem.

Config
------

```ruby
# setup redis connection
RedStats.redis = Redis.new
# or 
RedStats.redis = {host: port: } 

# set domain
RedStats.namespace = "my_domain"
```

Example usage
-------------

```ruby	
# tracks hits
RedStats.stat("http_connections/#{user}/#{ip}/#{controller}/#{action}")

# tracks downloads and filesizes to compute mean transfers
RedStats.stat("downloaded_files_sizes/#{user}/#{ip}/#{file_ext}", File.size(dowloaded_file))

# min and max also
RedStats.stat_w_minmax("http_connections/#{user}/#{ip}/#{controller}/#{action}", gen_time)

# get stats for path:
RedStats.get_stats("downloads/user1/127.0.0.1/robot.txt", :day, Time.now, -7)

# get childs for path:
RedStats.get_childs("downloads")
```

TODO:
-----
	
- purging too long stats 
- minute stats
- 15, 5 minute stats 
 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

