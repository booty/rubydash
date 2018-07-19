# frozen_string_literal: true

require "active_support/all"
require "dotiw"

class RubyDash
	class Item
		include ActionView::Helpers::DateHelper

		attr_reader :title, :created_at, :updated_at, :read, :details, :icon, :creator

		def initialize(stuff:)
			@title = stuff["title"].gsub(/\n/, " ").gsub(/\s+/, " ")
			@created_at = stuff["created_at"]
			@read = stuff["read"]
			@updated_at = stuff["updated_at"]
			@details = stuff["details"].gsub(/\n/, " ").gsub(/\s+/, " ") if stuff["details"]
			@icon = stuff["icon"]
			@creator = stuff["creator"]
		end

		def render
			render_item
			render_item_details
		end

	private

		def render_item
			dotiw = distance_of_time_in_words(Time.now, Time.at(@created_at), DOTIW_OPTIONS.call)

			left_side = "#{(@icon || DEFAULT_ICON).rjust(ITEM_INDENT_SPACES)} #{@title}"
			right_side = "#{@creator} (#{dotiw})"

			if left_side.length + right_side.length > OUTPUT_WIDTH
				right_side = "#{@creator.truncate(30, separator: /[\s\@\.]/, omission: '…')} (#{dotiw})"
			end

			if left_side.length + right_side.length > OUTPUT_WIDTH
				left_side = left_side.truncate(OUTPUT_WIDTH - right_side.length, separator: " ", omission: "… ")
			end

			print left_side.white.bold
			puts right_side.rjust(OUTPUT_WIDTH - left_side.length)
		end

		def render_item_details
			return unless @details
			# HTML.fragment renders HTML entities; common in email bodies
			details = Nokogiri::HTML.fragment(@details).to_s.truncate(OUTPUT_WIDTH - ITEM_INDENT_SPACES * 2, separator: ' ', omission: '… ')
			puts "#{' ' * (ITEM_INDENT_SPACES * 2 + 1)}#{details}".cyan.italic
		end
	end
end
