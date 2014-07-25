require 'optparse'
require 'open-uri'
require 'fileutils'
require 'json'

def api_request uri
  result = open(uri).read
  JSON.parse result
end

class BoardThread
  def initialize board, number
    @board = board
    @number = number
  end

  def posts
    @posts ||= api_request("http://a.4cdn.org/#{@board}/res/#{@number}.json")['posts']
  end

  def scrape
    posts.each do |post|
      FileUtils.mkpath "#{@number}"

      filename = "#{@number}/#{post['tim']}#{post['ext']}" if post['tim']
      if post['tim'] and !File.exist?(filename)
        puts "Downloading #{post['tim']}#{post['ext']}"
        File.write(filename, open("http://i.4cdn.org/#{@board}/src/#{post['tim']}#{post['ext']}").read)
      end
    end
  end
end

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
    puts "2.0"
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
    thread_url = ARGV[0].split("/")
    board = thread_url[3]
    threadno = thread_url[5]
    @thread = BoardThread.new(board, threadno)
end
loop do
  @thread.scrape
  puts "Waiting for #{options[:d]}..."
  sleep options[:d]
end
