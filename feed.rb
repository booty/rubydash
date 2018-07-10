# frozen_string_literal: true

# on disk: feed_name, fetched_at, failure_count

class RubyDash
	class Feed
		def initialize(name:, config:, cache:)
			@name, @config, @cache = name, config, cache
		end

		def fetch
			next_fetch_time = fetched_at + effective_ttl_seconds
			LOGGER.debug "[Feed#fetch] [#{@name}] Time.now.utc.to_i=#{Time.now.utc.to_i} next_fetch_time=#{next_fetch_time}"
			if next_fetch_time > Time.now.utc.to_i
				LOGGER.debug "[Feed#fetch] [#{@name}] Skipping fetch."
				return
			end
			LOGGER.debug "[Feed#fetch] [#{@name}] Not skipping fetch; will fetch_items_uncached"
			fetch_items_uncached
		end

		def render
			puts "--- #{@name} ---\n"
			@cache.get_items(feed_name: @name).each(&:render)
		end

	private

		def fetched_at
			@cache.fetched_at(feed_name: @name)
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
