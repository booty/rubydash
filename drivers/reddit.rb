# frozen_string_literal: true

require 'redd'

class RedditDriver < Driver
	def initialize(config)
		@config = config
	end

	def fetch_items_uncached
		my_messages.first(@config["Quantity"]).map do |msg|
			title, creator = title_and_creator(msg)
			stuff = {
				"title" => title,
				"created_at" => Time.at(msg.created_utc),
				"details" => msg.body,
				"read" => !msg.new?,
				"icon" => msg.new? ? "!" : nil,
				"creator" => creator
			}
			RubyDash::Item.new(
				stuff: stuff
			)
		end
	end

private
	def title_and_creator(msg)
		case (msg.title rescue msg.subject)
		when "comment reply"
			["Comment reply from #{msg.subreddit_name_prefixed}", "u/#{msg.author.name}"]
		when "post reply"
			["Post reply from #{msg.subreddit_name_prefixed}", "u/#{msg.author.name}"]
		when "username mention"
			["Mentioned in #{msg.subreddit_name_prefixed}", "u/#{msg.author.name}"]
		else
			["✉️  #{msg.subject}", "u/#{msg.author}"]
		end
	end

	def my_messages
		session.my_messages
	rescue StandardError => e
		raise RubyDash::Feed::FetchError, "#{e.class.name} #{e.to_s}"
	end

	def session
		Redd.it(
			user_agent: "RubyDash 0.1",
			client_id: @config["ClientId"],
			secret: @config["Secret"],
			username: @config["Username"],
			password: @config["Password"]
		)
	end
end
