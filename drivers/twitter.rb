# frozen_string_literal: true
require "twitter"

# Note: Getting information about a tweet's (status') engagement stats is very wonky
# Officially Twitter's API doesn't support it unless you subscribe to some enterprisey
# streaming API.
# We use a kludge to scrape this information instread for lack of a better alternative
class TwitterDriver < Driver
	def initialize(config)
		@config = config
	end

	def fetch_items_uncached
		user_timeline.first(@config["Quantity"]).map do |status|
			stuff = {
				"title" => "#{engagement(status)}#{status.text}",
				"created_at" => status.created_at,
				"read" => nil,
				"icon" => nil,
				"creator" => @config["Username"]
			}

			stuff["details"] = details(status)

			RubyDash::Item.new(
				stuff: stuff
			)
		end
	end

private

	def user_timeline
		client.user_timeline
	rescue StandardError => e
		raise RubyDash::Feed::FetchError, "#{e.class.name} #{e.to_s}"
	end

	def engagement(status)
		result = []
		result << "re:#{status.retweet_count}" if status.retweet_count.positive?
		result << "lk:#{status.favorite_count}" if status.favorite_count.positive?
		return nil if result.none?
		"#{result.join(', ')} ∙ "
	end

	def details(status)
		result = []
		result << user_names_who_retweeted(status)
		result << "Liked: #{user_names_who_liked(status.id)}" if status.favorite_count.positive?
		result.compact!
		return nil if result.none?
		result.join(" | ")
	end

	# Kludge due to API limitations
	def user_names_who_retweeted(status)
		return nil unless status.retweet_count.positive?
		url = "https://twitter.com/i/activity/retweeted_popup?id=#{status.id}"
		original_tweeter = status&.retweeted_status&.user&.screen_name
		names_to_reject = [original_tweeter, @config["Username"]].freeze
		names = HTTP.get(url).body.to_s.scan(/data-screen-name=\\"(.*?)\\"/).flatten.uniq.compact - names_to_reject
		return nil if names.none?
		"Retweeted: #{names.join(', ')}"
	end

	# Kludge due to API limitations
	def user_names_who_liked(id)
		(HTTP.get("https://twitter.com/i/activity/favorited_popup?id=#{id}").body.to_s.scan(/data-screen-name=\\"(.*?)\\"/).flatten.uniq - [@config["Username"]]).join(", ")
	end

	# Kludge due to API limitations
	def user_ids_who_liked_status(id)
		HTTP.get("https://twitter.com/i/activity/favorited_popup?id=#{id}").body.to_s.scan(/data-user-id=\\"(\d+)/).flatten.uniq
	end

	def client
		Twitter::REST::Client.new do |config|
			config.consumer_key = @config["ConsumerKey"]
			config.consumer_secret = @config["ConsumerSecret"]
			config.access_token = @config["AccessToken"]
			config.access_token_secret = @config["AccessSecret"]
		end
  end
end