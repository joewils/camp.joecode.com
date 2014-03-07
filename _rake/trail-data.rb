task :trail_data do
  # http://devwiki.everytrail.com/index.php/Main_Page
  puts "Trails"
  
  everytrail_url = 'http://www.everytrail.com/api/'
  everytrail_auth = [@keys['everytrail_key'], @keys['everytrail_secret']]

  campgrounds = YAML.load_file('_data/campgrounds.yml')

  # Activities
  # /api/activities?version=3
  url = everytrail_url+'activities?version=3'
  filename = '_xml/everytrail-activities.xml'
  if !File.exists?(filename)
    activities_xml = Nokogiri::XML(open(url, :http_basic_authentication=>everytrail_auth))      
    File.open(filename, 'w+') do |file|
      file.puts activities_xml
    end
  end

  # Search
  # /api/index/search?version=3&lat=1234&lon=1234&proximity=20
  campgrounds.each do |id,campground|
    url = everytrail_url+'index/search?version=3&lat='+campground['latitude']+'&lon='+campground['longitude']+'&proximity=20&activities=5&sort=proximity'
    filename = '_xml/campground-trails/'+id+'.xml'
    if !File.exists?(filename)
      trail_xml = Nokogiri::XML(open(url, :http_basic_authentication=>everytrail_auth))      
      File.open(filename, 'w+') do |file|
        file.puts trail_xml
      end
      sleep(1)
    end
  end

  # Process Trails
  trails = {}
  campground_trail_map = {}
  trail_campground_map = {}
  campgrounds.each do |id,campground|
    campground_trail_map[id] = []
    filename = '_xml/campground-trails/'+id+'.xml'
    if File.exists?(filename)
      trail_xml = Nokogiri::XML(open(filename)) 
      trail_xml.xpath('//guide').each do |guide|
        # Trail Data
        uid = 'G'+guide.attr('id')
        trails[uid] = {}
        trails[uid]['uid'] = uid
        trails[uid]['title'] = guide.xpath('./title').text.to_s
        trails[uid]['seo_title'] = guide.xpath('./url').text.to_s
        trails[uid]['sub_title'] = guide.xpath('./subtitle').text.to_s
        trails[uid]['overview'] = pize(guide.xpath('./overview').text.to_s)
        trails[uid]['tips'] = pize(guide.xpath('./tips').text.to_s)
        if guide.xpath('./picture/fullsize')
          trails[uid]['picture'] = guide.xpath('./picture/fullsize').text.to_s
        end
        trails[uid]['latitude'] = guide.xpath('./location').attr('lat').text.to_s
        trails[uid]['longitude'] = guide.xpath('./location').attr('lon').text.to_s
        trails[uid]['address'] = guide.xpath('./location').text.to_s
        # Campground Map
        if !campground_trail_map[id].include?(uid)
          campground_trail_map[id].push(uid)
        end
        # Trail Map
        if !trail_campground_map[uid]
          trail_campground_map[uid] = []
        end
        if !trail_campground_map[uid].include?(id)
          trail_campground_map[uid].push(id)
        end
        # Build Post
        trails[uid]['layout'] = 'trail'
        trails[uid]['categories'] = []
        trails[uid]['categories'][0] = 'trail'
        trails[uid]['categories'][1] = trails[uid]['seo_title']
        filename = '_posts/1975-05-31-' + uid + '.html'
        puts "\t" + filename
        File.open(filename, 'w+') do |file|
          file.puts trails[uid].to_yaml(line_width: -1)
          file.puts '---'
        end
      end
    end
  end

  # Export YAML
  filename = '_data/trails.yml'
  if !File.exists?(filename)
    puts filename
    File.open(filename, 'w+') do |file|
      file.puts trails.to_yaml(line_width: -1)
    end
  end

  filename = '_data/campground_trail_map.yml'
  if !File.exists?(filename)
    puts filename
    File.open(filename, 'w+') do |file|
      file.puts campground_trail_map.to_yaml(line_width: -1)
    end
  end

  filename = '_data/trail_campground_map.yml'
  if !File.exists?(filename)
    puts filename
    File.open(filename, 'w+') do |file|
      file.puts trail_campground_map.to_yaml(line_width: -1)
    end
  end

  # Export JSON
  filename = 'json/trails.json'
  if !File.exists?(filename)
    puts filename
    File.open(filename, 'w+') do |file|
      file.puts trails.to_json
    end
  end

  filename = 'json/campground_trail_map.json'
  if !File.exists?(filename)
    puts filename
    File.open(filename, 'w+') do |file|
      file.puts campground_trail_map.to_json
    end
  end

  filename = 'json/trail_campground_map.json'
  if !File.exists?(filename)
    puts filename
    File.open(filename, 'w+') do |file|
      file.puts trail_campground_map.to_json
    end

  end

  puts trails.length.to_s + " Trails"

end

def pize(string)
  string_array = string.split("\n\n")
  html = '<p>'
  string_array.each do |string|
    html += string + '</p><p>'
  end
  html += '</p>'
  html = html.gsub('<p></p>','')
  return html
end