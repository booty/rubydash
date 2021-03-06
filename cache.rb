# frozen_string_literal: true

require "sqlite3"

class RubyDash
	class Cache
		class IncorrectDatabaseSchemaVersion < StandardError; end

		def initialize(path:, current_schema_version:)
			@db = open_or_create_database(path, current_schema_version)
		end

		def get_items(feed_name:)
			# TODO: delete items if they're too old
			@db.execute("select * from items where feed_name=? order by created_at desc", feed_name).map do |result|
				Item.new(stuff: result)
			end
		end

		def set_items(feed_name:, items:)
			purge_items(feed_name: feed_name)
			items.each do |item|
				params = {
					feed_name: feed_name,
					created_at: item.created_at&.utc.to_i,
					updated_at: item.updated_at&.utc.to_i,
					fetched_at: Time.now.utc.to_i,
					title: item.title,
					creator: item.creator,
					read: (item.read ? 1 : 0),
					icon: item.icon,
					details: item.details,
					url: item.url
				}
				@db.execute("insert into items (feed_name, created_at, updated_at, fetched_at, title, creator, read, icon, details, url) values (:feed_name, :created_at, :updated_at, :fetched_at, :title, :creator, :read, :icon, :details, :url)", params)
				set_fetched_at(feed_name: feed_name)
			end
		end

		def failure_count(feed_name:)
			@db.get_first_value("select failure_count from fetch_histories where feed_name=?;", feed_name).to_i
		end

		def fetched_at(feed_name:)
			@db.get_first_value("select fetched_at from fetch_histories where feed_name=?;", feed_name).to_i
		end

		def set_fetched_at(feed_name:)
			params = {
				feed_name: feed_name,
				fetched_at: Time.now.utc.to_i,
			}
			@db.execute("INSERT INTO fetch_histories(feed_name, fetched_at, failure_count, last_failure_detail) VALUES (:feed_name, :fetched_at, 0, NULL) ON CONFLICT(feed_name) DO UPDATE set fetched_at=:fetched_at, failure_count=0, last_failure_detail=NULL", params)
		end

		def increment_failure_count(feed_name:, exception:)
			params = {
				feed_name: feed_name,
				fetched_at: Time.now.utc.to_i,
				last_failure_detail: exception.message,
			}
			@db.execute("INSERT INTO fetch_histories(feed_name, fetched_at, failure_count, last_failure_detail) VALUES (:feed_name, :fetched_at, 1, :last_failure_detail) ON CONFLICT(feed_name) DO UPDATE set fetched_at=:fetched_at, failure_count=failure_count+1, last_failure_detail=:fetched_at", params)
		end

	private

		def purge_items(feed_name:)
			@db.execute("delete from items where feed_name=?", feed_name)
		end

		def open_or_create_database(path, current_schema_version)
			db = open_database(path)
			schema_version = database_schema_version(db)
			LOGGER.info "[Cache#open_or_create_database] db's schema_version=#{schema_version} current_schema_version=#{current_schema_version}"
			return db if schema_version == current_schema_version
			initialize_database(path, current_schema_version)
		rescue SQLite3::SQLException
			initialize_database(path, current_schema_version)
		end

		# nukes the database and installs a fresh schema
		def initialize_database(path, current_schema_version)
			LOGGER.debug "[initialize_database] Let's initialize"
			close_database
			File.delete(path) if File.file?(path) # Quickest way to wipe the schema in SQlite
			db = open_database(path)
			db.execute "CREATE TABLE items(feed_name text, created_at datetime, updated_at datetime, fetched_at datetime, title text, creator text, read boolean, icon text, details text, url text);"
			db.execute "CREATE TABLE fetch_histories(feed_name text PRIMARY KEY, fetched_at datetime, failure_count integer, last_failure_detail text);"
			db.execute "CREATE TABLE schema_version(version integer);"
			db.execute "INSERT INTO schema_version(version) VALUES (#{current_schema_version});"
			db
		end

		def close_database
			@db.close if @db
		end

		def open_database(path)
			db = SQLite3::Database.new(path)
			db.results_as_hash = true
			db
		end

		def database_schema_version(db)
			db.get_first_value("SELECT version FROM schema_version;")
		end
	end
end
