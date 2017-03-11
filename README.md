# geocaching-friend-logs-bot
A simple Ruby crawl bot script for obtaining a user's geocache log details from the official geocaching page.

## Usage
```
gem install watir headless awesome_print
ruby geocaches_crawler.rb <Username> <How many caches to crawl>
```

The program will print a nicely formated JSON with the obtained data and save it to `out.json`. It will also inform to STDOUT about what it's doing right now.

You can exit anytime by inputting SIGINT (usually Ctrl+C). The bot will exit gracefully and output what has been crawled.

### Output data format
```
[{
  :url => 'URL of the cache',
  :code => 'GC Code',
  :name => 'Name of the cache',
  :user_log => 'Last log of the specified user',
  :user_log_date => 'Date of the log',
  :last_log => 'Last log of the cache',
  :last_log_date = >'Date of the log'
}, ...]
```
