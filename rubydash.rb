# frozen_string_literal: true

require "fileutils"
require "yaml"
require "pry-byebug"
require "titleize"
require "active_support/all"
require "action_view"
require "dotiw"
require "colorize"

require_relative "item"

DATA_PATH = File.join(ENV["HOME"], ".rubydash")
CONFIG_SAMPLE_FILE_NAME = "config-sample.yml"
CONFIG_SAMPLE_FILE_PATH = File.join(DATA_PATH, CONFIG_SAMPLE_FILE_NAME)
CONFIG_FILE_NAME = "config.yml"
CONFIG_FILE_PATH = File.join(DATA_PATH, CONFIG_FILE_NAME)
STATE_FILE_NAME = "state.yml"
STATE_FILE_PATH = File.join(DATA_PATH, STATE_FILE_NAME)
SEE_CONFIG_SAMPLE_MESSAGE = "See #{CONFIG_SAMPLE_FILE_PATH} for an example of how your #{CONFIG_FILE_NAME} might look."
STATE_SCHEMA_VERSION = 1
OUTPUT_WIDTH = 100

# Where the magic happens
class RubyDash
	include ActionView::Helpers::DateHelper

	def fetch
		# binding.pry
		items_by_feed_name = {}
		@config["Feeds"].each_pair do |name, feed|
			puts "Fetching feed #{name}"
			# TODO: get cached version from state, if extant
			driver = Object.const_get("#{feed['Type'].titleize}Driver").new(feed)
			items_by_feed_name[name] = driver.fetch_uncached
		end
		items_by_feed_name
	end

	def render(items_by_feed_name)
		items_by_feed_name.each do |feed_name, items|
			puts "--- #{feed_name} ---"
			items.each do |item|
				dotiw = distance_of_time_in_words(Time.now,
																					item.created_at,
																					compact: true,
																					highest_measures: 1,
																					two_words_connector: " ")
				indentor = "  • "
				icon = "#{item.icon}".strip
				title = "#{icon}  #{item.title}".strip

				print indentor
				print title.white.bold
				right_side = "#{item.from} (#{dotiw})"
				printf "%#{OUTPUT_WIDTH - title.length}s\n", right_side
				puts "    #{item.details.truncate(100 - identor.length, separator: ' ')}".cyan.italic if item.details
			end
		end
	end

	def initialize
		Dir.mkdir(DATA_PATH) unless File.directory?(DATA_PATH)
		unless File.file?(CONFIG_FILE_PATH)
			initialize_config_sample
			puts "You need to create #{CONFIG_FILE_PATH} to define your feeds."
			puts SEE_CONFIG_SAMPLE_MESSAGE
			exit(false)
		end
		@drivers = load_drivers
		puts "Loaded drivers: #{driver_names.join(', ')}"
		@config = load_validated_config
		@state = load_state
	end

private

	def initialize_config_sample
		FileUtils.cp(CONFIG_SAMPLE_FILE_NAME, CONFIG_SAMPLE_FILE_PATH)
	end

	def load_drivers
		Dir.glob("/Users/booty/proj/rubydash/drivers/*.rb").each do |filename|
			load(filename)
		end
		ObjectSpace.each_object(Class).select do |klass|
			klass < Driver
		end
	end

	def driver_names
		return [] unless @drivers
		@drivers.map do |klass|
			klass.name.gsub(/Driver\z/, "")
		end
	end

	def load_validated_config
		config = YAML.safe_load(File.read(CONFIG_FILE_PATH))
		validate_config!(config)
		config
	end

	def validate_config!(config)
		if config["Feeds"].nil? || config["Feeds"].empty?
			raise "The Feeds section of your configuration file is empty or missing. #{SEE_CONFIG_SAMPLE_MESSAGE}"
		end
		# TODO: check that the Type of each feed corresponds to an extent driver
	end

	def new_state
		feeds = @config["Feeds"].each_with_object({}) do |item, memo|
			memo[item[0]] = {
				type: item[0]["Type"],
				failure_count: 0
			}
		end
		{
			version: STATE_SCHEMA_VERSION,
			updated: Time.now.utc,
			feeds: feeds
		}
	end

	def load_state
		YAML.safe_load(File.read(STATE_FILE_PATH))
	rescue Errno::ENOENT => e
		new_state
	end
end

# puts String.colors                       # return array of all possible colors names
# puts String.modes                        # return array of all possible modes
# String.color_samples                # displays color samples in all combinations

# puts "Fuck you".yellow
# puts "Fuck you".light_cyan
# puts "Fuck you".light_cyan.italic

dashboard = RubyDash.new
items_by_feed_name = dashboard.fetch
dashboard.render(items_by_feed_name)
