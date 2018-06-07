# frozen_string_literal: true

class RubyDash
	class Item
		attr_accessor
		def initialize(title:, created_at:, read: nil, updated_at: nil, details: nil, icon: nil)
			@title = title
			@created_at = created_at
			@read = read
			@updated_at = updated_at
			@details = details
			@icon = icon
		end
	end
end
