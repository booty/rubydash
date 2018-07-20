# frozen_string_literal: true

require "active_support/all"
require "dotiw"

class RubyDash
	class Feed
		PADDING_CHAR = "⎯"
		include ActionView::Helpers::DateHelper

		class FetchError < StandardError; end

		def initialize(name:, config:, cache:)
			@name, @config, @cache = name, config, cache
		end

		def fetch
			LOGGER.debug "[Feed#fetch] [#{@name}] Time.now.utc=#{Time.now.utc} next_fetch_time=#{next_fetch_time}"
			if too_soon_for_fetch?
				LOGGER.debug "[Feed#fetch] [#{@name}] Skipping fetch."
				return
			end
			LOGGER.debug "[Feed#fetch] [#{@name}] Not skipping fetch; will fetch_items_uncached"
			fetch_items_uncached
		end

		def render
			puts header
			@cache.get_items(feed_name: @name).each(&:render)
		end

	private
		def header
			left_side = "#{PADDING_CHAR * (ITEM_INDENT_SPACES * 4)}| #{@name} |"
			fetched_time_ago = distance_of_time_in_words(fetched_at, Time.current, DOTIW_OPTIONS.call)
			next_fetch = distance_of_time_in_words(next_fetch_time, Time.current, DOTIW_OPTIONS.call)
			right_side = " #{fetched_time_ago} ago / in #{next_fetch}"
			padding_width = OUTPUT_WIDTH - left_side.length - right_side.length
			"#{left_side}#{PADDING_CHAR * padding_width}#{right_side}"
		end

		def too_soon_for_fetch?
			next_fetch_time > Time.now.utc
		end

		def next_fetch_time
			fetched_at + effective_ttl_seconds
		end

		def fetched_at
			Time.at(@fetched_at ||= @cache.fetched_at(feed_name: @name))
		end

		def failure_count
			# TODO: if the last attempt was a long time ago, we should reset
			# or maybe ignore the failure count
			@failure_count ||= @cache.failure_count(feed_name: @name)
		end

		def effective_ttl_seconds
			minimum_wait_seconds = @config["MinimumWaitSeconds"]
			ttl = if failure_count > 10
							minimum_wait_seconds * 10
						else
							minimum_wait_seconds * (failure_count + 1)
						end
			LOGGER.debug "[effective_ttl_seconds] ttl=#{ttl} minimum_wait_seconds=#{@config['minimum_wait_seconds']} failure_count=#{failure_count}"
			ttl
		end

		def fetch_items_uncached
			# TODO: reset failure count to zero if this is a success
			# TODO: increment failure count if this is not a success
			items = driver.fetch_items_uncached
			@cache.set_items(feed_name: @name, items: items)
		rescue FetchError => e
			@cache.increment_failure_count(feed_name: @name, exception: e)
		end

		def driver_class_name
			"#{@config['Type'].titleize}Driver"
		end

		def driver
			Object.const_get(driver_class_name).new(@config)
		rescue NameError => e
			# TODO: show proper driver path
			LOGGER.warn "There's a problem with the feed '#{@name}'... type is 'type', but I couldn't find a class named #{driver_class_name} in (driver path goes here)\n#{e}"
		end
	end
end
