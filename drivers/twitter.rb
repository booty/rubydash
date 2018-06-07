class TwitterDriver < Driver
	def fetch_uncached
		raise "Override me, please."
	end
end