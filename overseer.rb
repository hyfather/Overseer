require 'rubygems'
require 'sinatra'
require 'active_support'

ENVIRONMENTS_DATA_FILE="./ENV_DASHBOARD_DATA"
HUDSON_JOBS_DATA_FILE="./BUILD_STATUS_DATA"
NEWRELIC_DATA_FILE="./NEWRELIC_STATUS_DATA"

set :public, File.dirname(__FILE__) + '/views'
set :port, 10000

get '/' do
  @environments = []
  @environments_last_updated = timeago(File.mtime(ENVIRONMENTS_DATA_FILE))
  environments_data = File.new(ENVIRONMENTS_DATA_FILE, "r")
  environments_data.each_line do |line|
    values = line.chomp.split(/,/)
    @environments << {:name => values[0], :build => values[1], :branch => values[2], :dead => (values[3] == 'DEAD')}
  end

  @jobs = []
  @hudson_last_updated = timeago(File.mtime(HUDSON_JOBS_DATA_FILE))
  hudson_jobs_data = File.new(HUDSON_JOBS_DATA_FILE, "r")
  hudson_jobs_data.each_line do |line|
    values = line.split(/,/)
    @jobs << {:name => values[0], :status => values[1], :build_number => values[2], :commit_msg => values[3]}
  end


  newrelic_data = File.new(NEWRELIC_DATA_FILE, "r")
  newrelic_data.each_line do |line|
    @apdex = line.split(/,/)[1].to_f
  end

  erb :dashboard
end

# helper methods

def timeago(time, options = {})
   start_date = options.delete(:start_date) || Time.new
   date_format = options.delete(:date_format) || :default
   delta_minutes = (start_date.to_i - time.to_i).floor / 60
   if delta_minutes.abs <= (8724*60)
     distance = distance_of_time_in_words(delta_minutes)
     if delta_minutes < 0
        return "#{distance} from now"
     else
        return "#{distance} ago"
     end
   else
      return "on #{DateTime.now.to_formatted_s(date_format)}"
   end
end

 def distance_of_time_in_words(minutes)
   case
     when minutes < 1
       "less than a minute"
     when minutes == 1
       "#{minutes} minute"
     when minutes < 50
       "#{minutes} minutes"
     when minutes < 90
       "about one hour"
     when minutes < 1080
       "#{(minutes / 60).round} hours"
     when minutes < 1440
       "one day"
     when minutes < 2880
       "about one day"
     else
       "#{(minutes / 1440).round} days"
   end
 end
