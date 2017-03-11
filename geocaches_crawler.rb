require 'watir'
require 'headless'
require 'json'
require 'awesome_print'

$crawl_interval = 0.5
$links_to_crawl_count = 0
$links_to_crawl = []
$links_crawled = []
$crawled_data = []
$user_nick = nil
$crawler_thread = nil

def run_crawler(seed_url)
  puts '--- Running crawler'
  $crawler_thread = Thread.new do
    $links_to_crawl = grab_gc_links(seed_url).keys
    grab_gc_data_wrapper($links_to_crawl)
  end
end

def grab_gc_links(gc_links_url)
  puts '--- Grabbing geocache links'
  gc_links = {}
  headless = Headless.new
  headless.start
  browser = Watir::Browser.start gc_links_url

  # Get all cache links until desired limit reached
  while gc_links.length < $links_to_crawl_count do
    do_break = false
    table = browser.table class: 'SearchResultsTable'
    # Grab links from table
    if table.exists?
      table.links(:href, /geocache/).each do |link|
        if gc_links.length < $links_to_crawl_count
          puts link.href
          gc_links[link.href] = nil
        else
          do_break = true
          break
        end
      end
    end
    # Goto next page
    next_link = browser.link(:text => /Next|Následující/)
    break if do_break || !next_link.exists?
    next_link.click
  end

  browser.close
  headless.destroy

  return gc_links
end

def grab_gc_data(browser, gc_url)
  puts '- Grabbing data for ' + gc_url
  sleep($crawl_interval) # wait just in case there's a connection limit
  gc_data = {
    :url => nil,
    :code => nil,
    :name => nil,
    :user_log => '',
    :user_log_date => nil,
    :last_log => '',
    :last_log_date => nil
  }

  browser.goto gc_url
  gc_data[:url] = gc_url
  gc_data[:code] = browser.span(:id => 'ctl00_ContentBody_CoordInfoLinkControl1_uxCoordInfoCode').text
  gc_data[:name] = browser.span(:id => 'ctl00_ContentBody_CacheName').text
  xpath = "//td[.//a[contains(text(), '#{$user_nick}')]]"
  gc_data[:user_log] = browser.td(:xpath, xpath).span(:xpath, ".//span[contains(@class, 'LogText')]").text
  gc_data[:user_log_date] = browser.td(:xpath, xpath).span(:xpath, ".//span[contains(@class, 'LogDate')]").text
  gc_data[:last_log] = browser.span(:xpath, "//table[@id='cache_logs_table']//tbody//tr[1]//span[contains(@class, 'LogText')]").text
  gc_data[:last_log_date] = browser.span(:xpath, "//table[@id='cache_logs_table']//tbody//tr[1]//span[contains(@class, 'LogDate')]").text

  return gc_data
end

def grab_gc_data_wrapper(links_collection)
  puts '--- Grabbing geocache data'

  headless = Headless.new
  headless.start
  browser = Watir::Browser.start 'http://www.google.com'

  links_collection.each do |link|
    $crawled_data << grab_gc_data(browser, link)
  end

  browser.close
  headless.destroy
end

def stop_crawler
  puts '--- Stopping crawler'
  $crawler_thread.kill
end

def output_data
  puts "Number of scheduled caches = #{$links_to_crawl.length}"
  puts "Number of crawled caches = #{$crawled_data.length}"
  ap $crawled_data
  File.open('out.json', 'w') do |f|
    f.write($crawled_data.to_json)
  end
end


###############################################################################

# Intercept Ctrl+C
Signal.trap("INT") {
  puts "\nShutting down by request."
  stop_crawler
  output_data
  Kernel.exit
}

if !ARGV[0] || !ARGV[1]
  puts "Usage: ruby geocaches_crawler.rb <Username> <Limit>; end with Ctrl+C"
  exit
else
  $user_nick = ARGV[0]
  $links_to_crawl_count = ARGV[1].to_i
end

run_crawler("https://www.geocaching.com/seek/nearest.aspx?ul=#{$user_nick}")
$crawler_thread.join
output_data