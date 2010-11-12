require 'sinatra'
require 'haml'

require 'net/http'
require 'zlib'
require 'json'

get '/' do
  haml :index
end

post '/graph' do
  @tag = params["tag"]
  @url = get_charts_url(get_counts(@tag, 12))
#  @tag = "clojure"
#  @url = "http://clojure.org/space/showimage/clojure-icon.gif"
  haml :graph
end

SECS_MONTH = 30*24*60*60
CHARTS = "http://chart.apis.google.com/chart?cht=lc&chs=640x400&chxt=y&chd=t:"

def last_n_months(n)
  ret = []
  now = Time.now
  n.downto 1 do |i|
    ret.push(now-i*SECS_MONTH)
  end
  return ret
end

def inflate(string)
  gz = Zlib::GzipReader.new(StringIO.new(string))
  return gz.read
end  

def post(tag, from, to)
  url = URI.parse('http://api.stackoverflow.com/1.0/questions/');
  return Net::HTTP.post_form(url, {'tagged'=>tag,'fromdate'=>from, 'todate'=>to})
end

def get_counts(tag, n)
  last_n_months(n).map do |month|
    res = post(tag, (month-SECS_MONTH).to_i.to_s, month.to_i.to_s);
    JSON.parse(inflate(res.body))["total"].to_i
  end
end

def get_charts_url(list)
  str = ""
  str.concat(CHARTS)
  list.each {|x| str.concat(x.to_s).concat(",")}
  str = str.chop
  str.concat("&")
  max = list.max
  str.concat("chds=0,#{max}&chxr=0,0,#{max}")
  return str
end
