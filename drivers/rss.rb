# frozen_string_literal: true

require "rss"
require "open-uri"

class RssDriver < Driver
	def initialize(config)
		@config = config
	end

	def fetch_items_uncached
		open(@config["RssUrl"]) do |rss|
			feed = RSS::Parser.parse(rss)
			# puts "Title: #{feed.channel.title}"

			return	feed.items.first(@config["Quantity"]).map do |item|
								stuff = {
									"title" => item.title,
									"created_at" => item.pubDate,
									"details" => item.description.gsub(/<\/?[^>]*>/, ""),
									"read" => nil,
									"icon" => nil,
									"creator" => item.dc_creator,
									"url" => item.link,
								}
								RubyDash::Item.new(
									stuff: stuff
								)
						  end
		end
	end
end
