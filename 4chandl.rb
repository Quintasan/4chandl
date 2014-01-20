require 'open-uri'
require 'net/http'
require 'json'
require 'fileutils'
require 'pathname'
require 'optparse'

#Deafult interval is 60 seconds
options = { :d => 60 }

opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: 4chandl.rb <thread url> [delay]"
  opts.separator ""

  opts.on("-d", "--delay [N]", Integer, "Set the interval to N seconds. If not") do |delay|
    options[:d] = delay
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on_tail("--version", "Show version") do
    puts "1.0"
    exit
  end
end

opt_parser.parse!

if ARGV.empty?
  puts opt_parser
  exit (-1)
end
if !(ARGV[0] =~ /^#{URI::regexp}$/)
    puts "You have not provided a valid URL"
    puts "Example: http://boards.4chan.org/w/res/1620347"
    puts " "
    puts opt_parser
    exit(-1)
else
    thread_url = ARGV[0]
end
loop do
  begin
    body = open(thread_url + ".json").read
  rescue OpenURI::HTTPError => e
    if e.message == '404 Not Found'
      puts "Thread 404'd. Exiting."
      exit(1)
    else
      raise e
    end
  end
  posts = JSON.load(body)['posts']
  posts = posts.select { |p| p.include? 'ext' }
  threadno = posts.first['no']
  FileUtils.mkpath "#{threadno}"
  posts.each do |post|
    url = thread_url
    url = url.gsub(/boards/, 'images')
    url = url.gsub(/res/, 'src')
    url = url.chomp("#{threadno}")
    url << "#{post['tim']}#{post['ext']}"
    next if Pathname.new("#{threadno}/#{post['tim']}#{post['ext']}").exist?
    puts "Downloading #{post['tim']}#{post['ext']}"
    File.write("#{threadno}/#{post['tim']}#{post['ext']}", Net::HTTP.get(URI.parse(url)))
  end
  puts "Waiting for #{options[:d]}..."
  sleep options[:d]
end
