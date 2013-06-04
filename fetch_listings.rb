require 'nokogiri'
require 'open-uri'

languages = { "java"    => "Java",
              "ruby"    => "Ruby",
              "python"  => "Python",
              "perl"    => "Perl",
              "cpp"     => "C++",
              "c-sharp"  => "C#",
              "javascript" => "JavaScript",
              "jquery" => "jQuery",
              "dot-net"  => ".Net"
            }

# Store API publisher id in external config file to prevent unauthorized use
#
publisher = File.read("publisher.txt").chop

def request_url(publisher, lang, start, limit, from_age, job_type)

  "http://api.indeed.com/ads/apisearch?publisher=#{publisher}" +
    "&q=title:" + URI::encode(lang) + "%28programmer%20OR%20engineer%20OR%20developer%29" +
    "&l=richmond%2C+bc&sort=date&radius=50&st=" +
    "&jt=#{job_type}" +
    "&start=#{start}&limit=#{limit}&fromage=#{from_age}&" +
    "filter=&latlong=1&co=ca&chnl=&userip=1.2.3.4&" +
    "useragent=Mozilla/%2F4.0%28Firefox%29&v=2"
end

def extract_results(lang, request)
  doc = Nokogiri::XML(open(request))

  result_total = doc.xpath('/response/totalresults/text()').to_s
  result_start = doc.xpath('/response/start/text()').to_s
  result_end = doc.xpath('/response/end/text()').to_s

  puts lang + ": " + result_total
  puts "   " + result_start + " - " + result_end

  results = doc.xpath('/response/results/result')

  results.each_with_index do |result, i|
    puts "#{i + 1}: #{result.xpath('date/text()').to_s} - " +
    result.xpath('jobtitle/text()').to_s + " - " +
    result.xpath('company/text()').to_s
  end

  return result_total.to_i, result_end.to_i
end

languages.each do |id,lang|

  start = 0
  limit = 999
  from_age = nil
  job_type = "fulltime"

  # first pass through results for given language
  #
  request = request_url(publisher, lang, start, limit, from_age, job_type)
  result_total, result_end = extract_results(lang, request)

  # API returns results in batches of 25
  # continue requests as long as there are more results to fetch
  #
  while result_end < result_total do
    request = request_url(publisher, lang, result_end, limit, from_age, job_type)
    result_total, result_end = extract_results(lang, request)
  end

end

