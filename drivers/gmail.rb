# frozen_string_literal: true

require "google/apis/gmail_v1"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

# Adapted from https://developers.google.com/gmail/api/quickstart/ruby
class GmailDriver < Driver
	OOB_URI = "urn:ietf:wg:oauth:2.0:oob"
	APPLICATION_NAME = "RubyDash"
	CREDENTIALS_PATH = "token.yaml"
	SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY

	def initialize(config)
		@config = config
	end

	def fetch_uncached
		# Initialize the API ok
		service = Google::Apis::GmailV1::GmailService.new
		service.client_options.application_name = APPLICATION_NAME
		service.authorization = authorize

		# Show the user's labels
		user_id = "me"
		# binding.pry
		# result = service.list_user_labels(user_id)
		# puts "Labels:"
		# puts "No labels found" if result.labels.empty?
		# result.labels.each { |label| puts "- #{label.name}" }

		# TODO: allow user to configure label(s)
		# service.list_user_messages("me", max_results: 25, label_ids: "Label_18")

		# AMQ-Delivery-Message-Id, ARC-Authentication-Results,
		# ARC-Authentication-Results, ARC-Message-Signature, ARC-Message-Signature,
		# ARC-Seal, ARC-Seal, Authentication-Results, Content-Transfer-Encoding,
		# Content-Type, DKIM-Signature, Date, Delivered-To, Delivered-To, From,
		# MIME-Version, Message-Id, PP-Correlation-Id, Received, Received, Received,
		# Received, Received, Received-SPF, Received-SPF, Return-Path, Return-Path,
		# Subject, To, X-Email-Type-Id, X-Forwarded-For, X-Forwarded-To, X-Gm-Message-State,
		# X-Google-DKIM-Signature, X-Google-Smtp-Source, X-MaxCode-Template, X-PP-Email-transmission-Id,
		# X-PP-REQUESTED-TIME, X-Received, X-Received, X-Received
		label_id = get_label_id(user_id, service, "CATEGORY_PERSONAL")
		msgs_metadata = service.list_user_messages("me", max_results: 10, label_ids: @config["Label"]).messages
		# debug = true
		binding.pry
		msgs_metadata.map do |msg_metadata|
			msg = service.get_user_message(user_id, msg_metadata.id, format: "metadata", metadata_headers: %w[Subject From])
			headers = msg.payload.headers
			# binding.pry if debug
			# debug = false
			RubyDash::Item.new(
				title: get_header_value(headers, "Subject"),
				created_at: Time.at(msg.internal_date / 1000),
				details: msg.snippet,
				read: !msg.label_ids.include?("UNREAD"),
				icon: msg.label_ids.include?("UNREAD") ? "✉️" : ""
			)
		end
	end

private

	def get_label_id(user_id, service, label_name)
		service.list_user_labels(user_id).labels.find { |l| l.name == label_name }&.id
	end

	def get_header_value(headers, header_name)
		headers.find { |h| h.name == header_name }.value
	end

	# Ensure valid credentials, either by restoring from the saved credentials
	# files or intitiating an OAuth2 authorization. If authorization is required,
	# the user's default browser will be launched to approve the request.
	# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
	def authorize
		client_id = Google::Auth::ClientId.new(@config["AuthKey"], @config["AuthSecret"])
		token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
		authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
		user_id = "default"
		credentials = authorizer.get_credentials(user_id)
		if credentials.nil?
			url = authorizer.get_authorization_url(base_url: OOB_URI)
			puts "Open the following URL in the browser and enter the " \
					 "resulting code after authorization:\n" + url
			code = gets
			credentials = authorizer.get_and_store_credentials_from_code(
				user_id: user_id, code: code, base_url: OOB_URI
			)
		end
		credentials
	end
end
