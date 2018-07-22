# frozen_string_literal: true

require "fileutils"
require "yaml"
require "pry-byebug"
require "titleize"
require "action_view"
require "colorize"
require "terminfo"
require "logger"
require "faker"

require_relative "utils"
require_relative "item"
require_relative "cache"
require_relative "feed"

DATA_PATH = File.join(ENV["HOME"], ".rubydash")
CONFIG_SAMPLE_FILE_NAME = "config-sample.yml"
CONFIG_SAMPLE_FILE_PATH = File.join(DATA_PATH, CONFIG_SAMPLE_FILE_NAME)
CONFIG_FILE_NAME = "config.yml"
CONFIG_FILE_PATH = File.join(DATA_PATH, CONFIG_FILE_NAME)
CACHE_FILE_NAME = "cache.sqlite3"
CACHE_FILE_PATH = File.join(DATA_PATH, CACHE_FILE_NAME)
SEE_CONFIG_SAMPLE_MESSAGE = "See #{CONFIG_SAMPLE_FILE_PATH} for an example of how your #{CONFIG_FILE_NAME} might look."
CACHE_SCHEMA_VERSION = 4
ITEM_INDENT_SPACES = 2
OUTPUT_WIDTH = TermInfo.screen_size[1] - ITEM_INDENT_SPACES
DEFAULT_ICON = ""
LOGGER = Logger.new("/tmp/rubydash.log")

# For development use; such as getting fake data for use in screenshots, etc
USE_FAKER = ARGV.include?("--faker")

# This is horrible and I promise to replace it with something better
# We can't simply store the hash in a constant and reuse it because
# the dotiw gem calls #delete on the options hash you pass to it,
# so we actually need a new hash each time
DOTIW_DEFAULTS = { compact: true, highest_measures: 1, two_words_connector: " " }.freeze
DOTIW_OPTIONS = -> { DOTIW_DEFAULTS.dup }

# Where the magic happens
class RubyDash
	attr_reader :state, :drivers, :config

	def fetch
		@config["Feeds"].each do |name, config|
			Feed.new(name: name, config: config, cache: @cache).fetch
		end
	end

	def render
		@config["Feeds"].each do |name, config|
			Feed.new(name: name, config: config, cache: @cache).render
		end
	end

	def initialize
		LOGGER.info "--- Init ---"
		@config = load_validated_config
		Dir.mkdir(DATA_PATH) unless File.directory?(DATA_PATH)
		initialize_config_sample_if_needed
		@drivers = load_drivers
		LOGGER.info "Loaded drivers: #{driver_names.join(', ')}"
		@cache = Cache.new(path: CACHE_FILE_PATH, current_schema_version: CACHE_SCHEMA_VERSION)
	end

private

	def initialize_config_sample_if_needed
		return if File.file?(CONFIG_FILE_PATH)
		FileUtils.cp(CONFIG_SAMPLE_FILE_NAME, CONFIG_SAMPLE_FILE_PATH)
		raise "You need to create #{CONFIG_FILE_PATH} to define your feeds. \n#{SEE_CONFIG_SAMPLE_MESSAGE}"
	end

	def load_drivers
		# TODO: path needs to be relative
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
end

# puts String.colors                       # return array of all possible colors names
# puts String.modes                        # return array of all possible modes
# String.color_samples                # displays color samples in all combinations

dashboard = RubyDash.new
dashboard.fetch
dashboard.render
