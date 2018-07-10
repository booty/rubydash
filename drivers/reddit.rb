# frozen_string_literal: true

require 'redd'

class RedditDriver < Driver
	def initialize(config)
		@config = config
	end

	def fetch_items_uncached
		session = Redd.it(
			user_agent: "RubyDash 0.1",
			client_id: @config["ClientId"],
			secret: @config["Secret"],
			username: @config["Username"],
			password: @config["Password"]
		)
		session.my_messages.first(@config["Quantity"]).map do |msg|
			title, creator = case msg.subject
											 when "comment reply"
												 ["Comment reply from #{msg.subreddit_name_prefixed}", "u/#{msg.author.name}"]
											 else
												 ["[Private] #{msg.subject}", "u/#{msg.author}"]
											 end
			stuff = {
				"title" => title,
				"created_at" => Time.at(msg.created_utc),
				"details" => msg.body,
				"read" => !msg.new,
				"icon" => msg.new ? "!" : nil,
				"creator" => creator
			}
			RubyDash::Item.new(
				stuff: stuff
			)
		end
	end
end
