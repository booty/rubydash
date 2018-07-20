# frozen_string_literal: true

class String
	# Currently this will work in iTerm2, GNOME Terminal, and other VTE based terminals
	# ref: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda
	# Obvious TODO: detect hyperlink support in the terminal or at least make this configurable
	def hyperlink(label: nil)
		label ||= self
		"\e]8;;#{self}\a#{label}\e]8;;\a"
	end

	def printable_length
		self.gsub(/\e\]8;;.*?\a/, "").gsub(/[^[:print:]]/, "").length
	end
end
