task :campground_data do

  # Get Campgrounds
  @states.each do |state|
    filename = '_xml/campgrounds-' + state.downcase + '.xml'
    puts filename
    if !File.exists?(filename)
      doc = Nokogiri::XML(open('http://api.amp.active.com/camping/campgrounds?pstate='+state+'&api_key='+@active_key))
      File.open(filename, 'w+') do |file|
        file.puts doc
      end
      sleep(2)
    end
  end

  # Build Campgrounds Data
  campgrounds = {}
  @states.each do |state|
    filename = '_xml/campgrounds-' + state.downcase + '.xml'
    doc = Nokogiri::XML(open(filename))
    doc.xpath('//result').each do |result|
      campground = {}
      result.attributes().each do |id, attribute|
        campground[id.to_s] = attribute.to_s
      end
      uid = state + campground['facilityID'].to_s
      campground['uid'] = uid
      campground['title'] = fix_title(campground['facilityName'])
      campground['layout'] = 'campground'
      campground['categories'] = []
      campground['categories'][0] = state.downcase
      campground['categories'][1] = seo_string(campground['title'])
      campgrounds[uid] = campground unless campground['contractType'] == 'PRIVATE'
    end
  end

  # Export YAML
  filename = '_data/campgrounds.yaml'
  puts filename
  File.open(filename, 'w+') do |file|
    file.puts campgrounds.to_yaml(line_width: -1)
  end

  # Export JSON
  filename = 'json/campgrounds.json'
  puts filename
  File.open(filename, 'w+') do |file|
    file.puts campgrounds.to_json
  end

  # Get Details
  campgrounds.each do |id, campground|
    document_path = 'http://api.amp.active.com/camping/campground/details?contractCode='+campground['contractID']+'&parkId='+campground['facilityID']+'&api_key='+@active_key
    filename = '_xml/campground/' + id + '.xml'
    puts filename
    if !File.exists?(filename)
      doc = Nokogiri::XML(open(document_path))
      File.open(filename, 'w+') do |file|
        file.puts doc
      end
      sleep(2)
    end
  end

  # Process Details
  campgrounds.each do |id, campground|
    filename = '_xml/campground/' + id + '.xml'
    puts "\t" + filename
    doc = Nokogiri::XML(open(filename))

    # Description
    doc.xpath('./detailDescription').each do |node|
      node.attributes().each do |id, attribute|
        clean_up = ['description',
                    'drivingDirection',
                    'facilitiesDescription',
                    'importantInformation',
                    'nearbyAttrctionDescription',
                    'orientationDescription',
                    'recreationDescription',
                    'note'
                  ]
        if clean_up.include? id
          campground[id.to_s] = pize(attribute.to_s)
        else 
          campground[id.to_s] = attribute.to_s
        end
      end
    end

    # address
    campground['address'] = []
    doc.xpath('./detailDescription/address').each_with_index do |node, index|
      campground['address'][index] = {}
      node.attributes().each do |id, attribute|
        campground['address'][index][id.to_s] = attribute.to_s
      end
    end

    # informationLink
    campground['links'] = []
    doc.xpath('./detailDescription/informationLink').each_with_index do |node, index|
      campground['links'][index] = {}
      node.attributes().each do |id, attribute|
        campground['links'][index][id.to_s] = attribute.to_s
      end
    end

    # photo
    campground['photos'] = []
    doc.xpath('./detailDescription/photo').each do |node|
      if node.attr('pbsrc')
        campground['photos'].push(node.attr('pbsrc'))
      end
    end

    # contact
    campground['contact'] = []
    doc.xpath('./detailDescription/contact').each_with_index do |node, index|
      campground['contact'][index] = {}
      node.attributes().each do |id, attribute|
        campground['contact'][index][id.to_s] = attribute.to_s
      end
    end

    # amenity
    campground['tags'] = []
    doc.xpath('./detailDescription/amenity').each do |node|
      if node.attr('name')
        campground['tags'].push(hash_tag(node.attr('name')))
      end
    end

    # Build Post
    filename = '_posts/1975-05-31-' + campground['uid'] + '.html'
    puts "\t" + filename
    File.open(filename, 'w+') do |file|
      file.puts campground.to_yaml(line_width: -1)
      file.puts '---'
    end

  end

end

def pize(string)
  string = string.gsub('     ','~')
  string = string.gsub('    ','~')
  string = string.gsub('&lt;','<')
  string = string.gsub('&gt;','>')
  string_array = string.split('~')
  html = '<p>'
  string_array.each do |string|
    html += string + '</p><p>'
  end
  html += '</p>'
  html = html.gsub('<p></p>','')
  return html
end

def fix_title(title)
  title = title.titlecase
  # Fix States
  @states.each do |state|
    title = title.gsub(state.titlecase, state.upcase)
  end  
  return title
end

def seo_string (string)
  string = string.strip()
  string = string.gsub('-','')
  string = string.gsub('+','')
  string = string.gsub('"','')
  string = string.gsub('/','-')
  string = string.gsub('.','-')
  string = string.gsub(' ','-')
  string = string.gsub('\'','')
  string = string.gsub('&','')
  string = string.gsub(',','')
  string = string.gsub('(','')
  string = string.gsub(')','')
  string = string.gsub('----','-')
  string = string.gsub('---','-')
  string = string.gsub('--','-')
  string = string.gsub(':','')
  string = string.downcase
  return string
end

def hash_tag (name)
  hash_tag = name.strip()
  hash_tag = hash_tag.titlecase
  hash_tag = hash_tag.gsub(' ','')
  hash_tag = hash_tag.gsub('\\','')
  hash_tag = hash_tag.gsub('/','')
  hash_tag = '#'+hash_tag
  return hash_tag
end
