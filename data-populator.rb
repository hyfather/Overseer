require "rubygems"
require "open-uri"
require "active_support"

HUDSON_JOBS_TO_MONITOR = ['mmh', 'mmh_stress_release', 'mmh_hotfix_release', 'mmh-indexer', 'mmh-indexer-branch-hotfix'] 
MML_URLS_TO_MONITOR = ['mmhtestqa.kih.kmart.com', 'mmhbuild02p.ecom.sears.com:8180', 'mmh-stress1.ecom.sears.com', 'www.managemylife.com']

ENVIRONMENTS_DATA_FILE = "./ENV_DASHBOARD_DATA"
HUDSON_JOBS_DATA_FILE = "./BUILD_STATUS_DATA"

def translate_color(hudson_job_color)
  {"blue" => "green", "blue_anime" => "green building", "red" => "red", "red_anime" => "red building", "yellow" => "yellow", "yellow_anime" => "yellow building"}[hudson_job_color]
end


# process hudson jobs
jobs = ""
begin
  outer_json = open("http://mmhbuild01p.ecom.sears.com:8080/hudson/api/json").read
  outer_hash = ActiveSupport::JSON.decode(outer_json)



  outer_hash["jobs"].each do |job|
    if HUDSON_JOBS_TO_MONITOR.include? job["name"]
      url = "http://mmhbuild01p.ecom.sears.com:8080/hudson/job/#{job["name"]}/lastBuild/api/json"
      last_build_json = open(url).read
      last_build_hash = ActiveSupport::JSON.decode(last_build_json)


      commit_message = (last_build_hash["changeSet"]["items"].try(:first))
      commit_message = commit_message.nil? ? "No Changeset. Build was triggered manually or by upstream!" : commit_message["msg"]
      commit_message.gsub!(/,|<|>|\//, ' ')

      jobs << [job["name"], translate_color(job["color"]), last_build_hash["number"], commit_message].join(",")
      jobs << "\n"

    end
  end
rescue Exception => e
  p e.inspect
  jobs = ""
end

file_handle = File.new(HUDSON_JOBS_DATA_FILE, "w")
file_handle.print jobs
file_handle.close


# process environments data file.
environments = ""
MML_URLS_TO_MONITOR.each do |url|
  begin
    all_properties = open("http://" + url + "/mmh/version.properties").read
    csv_string = ([url, all_properties.split(/\n|=/)[1], all_properties.split(/\n|=/)[3]].join(",") + "\n")
  rescue Exception
    csv_string = url + ",-,-,DEAD\n"
  end

  environments << csv_string
end

file_handle = File.new(ENVIRONMENTS_DATA_FILE, "w")
file_handle.print environments
file_handle.close


