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
	task :start_honeypots do
		start_honeypots
	end

	task :stop_honeypots do
		stop_honeypots
	end
end
