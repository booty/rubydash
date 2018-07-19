require "twitter"

class TwitterDriver < Driver
	def initialize(config)
		@config = config
	end

	def fetch_items_uncached
		client.user_timeline.first(@config["Quantity"]).map do |status|
			stats = []
			stats << "re:#{status.retweet_count}" if status.retweet_count > 0
			stats << "lk:#{status.favorite_count}" if status.favorite_count > 0
			stat_summary = if stats.any?
											"#{stats.join(', ')} | "
										 else
										 	""
										 end

			stuff = {
				"title" => "#{stat_summary}#{status.text}",
				"created_at" => status.created_at,
				"read" => nil,
				"icon" => nil,
				"creator" => @config["Username"]
			}

			details = []
			details << "Retweeted: #{user_names_who_retweeted(status.id)}" if status.retweet_count.positive?
			details << "Liked: #{user_names_who_liked(status.id)}" if status.favorite_count.positive?
			stuff["details"] = details.join(" | ") if details.any?

			RubyDash::Item.new(
				stuff: stuff
			)
		end
	end

private

	def user_names_who_retweeted(id)
		(HTTP.get("https://twitter.com/i/activity/retweeted_popup?id=#{id}").body.to_s.scan(/data-screen-name=\\"(.*?)\\"/).flatten.uniq - [@config["Username"]]).join(", ")
	end

	def user_names_who_liked(id)
		(HTTP.get("https://twitter.com/i/activity/favorited_popup?id=#{id}").body.to_s.scan(/data-screen-name=\\"(.*?)\\"/).flatten.uniq - [@config["Username"]]).join(", ")
	end

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