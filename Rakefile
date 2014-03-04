require 'nokogiri'
require 'open-uri'
require 'pp'
require 'date'
require 'yaml'
require 'json'
require 'csv'
require 'active_support/core_ext/hash/conversions'

@keys = YAML.load_file('_config/keys.yml')

@states = ['WA','ID','MT','OR']
  
# :campground_data
import '_rake/campground-data.rb'

# :trail_data
import '_rake/trail-data.rb'

desc "TODO"
task :default => []