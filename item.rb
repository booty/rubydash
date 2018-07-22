# frozen_string_literal: true

require "active_support/all"
require "dotiw"

class RubyDash
	class Item
		include ActionView::Helpers::DateHelper

		attr_reader :title, :created_at, :updated_at, :read, :details, :icon, :creator, :url

		def initialize(stuff:)
			@title = stuff["title"].gsub(/\n/, " ").gsub(/\s+/, " ")
			@created_at = stuff["created_at"]
			@read = stuff["read"]
			@updated_at = stuff["updated_at"]
			@details = stuff["details"].gsub(/\n/, " ").gsub(/\s+/, " ") if stuff["details"]
			@icon = stuff["icon"]
			@creator = stuff["creator"]
			@url = stuff["url"]
		end

		def render(feed_config:)
			fake_me if USE_FAKER
			render_item(feed_config: feed_config)
			render_item_details(feed_config: feed_config)
		end

	private

		def render_item(feed_config:)
			dotiw = distance_of_time_in_words(Time.now, Time.at(@created_at), DOTIW_OPTIONS.call)
			title = if @url
								@url.hyperlink(label: @title)
							else
								@title
							end
			left_side = "#{(@icon || DEFAULT_ICON).rjust(1)} #{title}"
			creator = @creator if feed_config["ShowCreator"]
			right_side = "#{creator} (#{dotiw})".strip

			if left_side.printable_length + right_side.length > OUTPUT_WIDTH
				right_side = "#{@creator.truncate(30, separator: /[\s\@\.]/, omission: '…')} (#{dotiw})"
			end

			if left_side.printable_length + right_side.length > OUTPUT_WIDTH
				left_side = left_side.truncate(OUTPUT_WIDTH - right_side.length, separator: " ", omission: "… ")
			end

			print left_side
			puts right_side.rjust(OUTPUT_WIDTH - left_side.printable_length)
		end

		def render_item_details(feed_config:)
			return unless @details
			return if feed_config["NeverShowDetails"]
			return if feed_config["OnlyShowDetailsIfUnread"] && @read
			# HTML.fragment renders HTML entities; common in email bodies
			details = Nokogiri::HTML.fragment(@details).to_s.truncate(OUTPUT_WIDTH - ITEM_INDENT_SPACES * 2, separator: ' ', omission: '… ')
			puts "#{' ' * (ITEM_INDENT_SPACES * 2)}#{details}".cyan.italic
		end

		# OK. Fake_me, fake_string, etc are very kludgy
		#
		# Use case: very roughly sanitize displayed data for
		# development purposes. (Suppose you want to share a screenshot
		# with another deveoper, but you don't want to screencap and
		# share your personal bizness)

		def fake_me
			@title = fake_string(@title)
			@details = fake_string(@details)
			@creator = fake_string(@creator)
		end

		def fake_string(str)
			return if str.nil?
			original_words = str.split
			faker_words = faker_words()
			new_words = []
			is_email = false
			original_words.each_with_index do |word, i|
				new_words << if word =~ /^@/
										 	 fake_handle("@")
										 elsif word =~ /u\//
										 	 fake_handle("u/")
										 elsif word =~ /r\//
										 	 fake_subreddit
										 elsif ["Liked:", "Retweeted:", "Comment", "reply", "from", "Mentioned", "✉", "Post", "re:", "RE:", "|"].include?(word)
										 	 word
										 elsif word =~ /<.*?@.*?>/
										 	 is_email = true
										 	 "boop!"
										 else
										 	 faker_words[i]
										 end
			end
			if is_email
				return "#{Faker::Name.name} <#{Faker::Internet.safe_email}>"
			end
			if new_words.length > 2
				new_words.join(" ") + ["!",".",".","?",".","...","..."].sample
			else
				new_words.join(" ")
			end
		end

		def fake_subreddit
			"r/#{Faker::Dune.planet.downcase}"
		end

		def fake_handle(prefix)
			"#{prefix}#{Faker::Hipster.words(1..3).map { |s| s2 = s.dup; s2[0] = s2[0].upcase; s2 }.join}"
		end

		def faker_words
			result = []
			1.upto(10) do
				result << Faker::Dune.quote
				result << " "
			end
			result.join(" ").split
		end
	end
end
