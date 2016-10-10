require 'yaml'
require 'time'
require 'json'

path_moof = "/Users/barry/data-2016-10-02/posts"
path_new  = "/Users/barry/Desktop/json/entries"

Dir.glob("#{path_moof}/**/*.md").each do |file|

  puts "Reading #{file}"

  raw = File.read(file)
  raw_parts = raw.split(/---\n/)

  properties = {}
  properties['content'] = [raw_parts[2].to_s] unless raw_parts[2].to_s.empty?

  begin
    data = YAML.load(raw_parts[1])
  rescue
    puts raw
    raise
  end

  data.keys.each do |key|
    case key
    when 'syndications'
      k = 'syndication'
    when 'bookmark'
      k = 'bookmark-of'
    when 'in_reply_to'
      k = 'in-reply-to'
    when 'like_of'
      k = 'like-of'
    when 'repost_of'
      k = 'repost-of'
    when 'place_name'
      k = 'place-name'
    when 'post_type'
      k = 'post-type'
    when 'permalink', 'latitude', 'longitude'
      next
    else
      k = key
    end

    properties[k] = Array(data[key])

    if key == 'published'
      properties[key] = [Time.parse(data[key]).utc.iso8601.to_s]
    elsif k == 'photo'
      # TODO move old photos to s3
      properties[key] = ["https://barryfrost.com/photos/#{data[key]}"]
    end
  end

  file_content = {
    type: ['h-entry'],
    properties: properties
  }.to_json

  date = Time.parse(data['published']).utc
  url = date.strftime('/%Y/%m/') + data['slug']
  new_file = "#{path_new}#{url}.json"

  FileUtils.mkdir_p( File.dirname(new_file) )

  File.write(new_file, file_content)

end