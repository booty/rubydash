# frozen_string_literal: true

class RubyDash
	class Item
		attr_reader :title, :created_at, :read, :details, :icon, :from
		def initialize(title:, created_at:, read: nil, updated_at: nil, details: nil, icon: nil, from: nil)
			@title = title
			@created_at = created_at
			@read = read
			@updated_at = updated_at
			@details = details
			@icon = icon
			@from = from
		end
	end
end
