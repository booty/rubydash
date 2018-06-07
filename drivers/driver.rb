# frozen_string_literal: true

# The class from which other drivers should inherit.
# (It's the ersatz Ruby equivalent of an abstract class)
class Driver
	def fetch_uncached
		raise "Override me, please."
	end
end
