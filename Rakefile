require_relative 'app'

task :test do
	Dir.glob('./test/test_*.rb') { |f| require f }
end

namespace :db do
	DB.loggers << Logger.new($stdout)

	task :migrate do
		Sequel.extension :migration
		Sequel::Migrator.run(DB, 'db/migrations')
	end

	task :attacks_clear do
		attacks_delete
	end

	task :attacks_populate do
		attacks_populate
	end
end

namespace :aws do
	if ENV['AWS_ACCESS_KEY'].nil?
		puts 'AWS_ACCESS_KEY is not set!'
		exit
	elsif ENV['AWS_SECRET_KEY'].nil?
		puts 'AWS_SECRET_KEY is not set!'
		exit
	end

	task :start_honeypots do
		start_honeypots
	end

	task :list_honeypots do
		list_honeypots
	end

	task :stop_honeypots do
		stop_honeypots
	end
end
