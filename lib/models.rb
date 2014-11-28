if ENV['DATABASE_URL'].nil?
	puts 'DATABASE_URL is not set!'
	exit
end

DB = Sequel.connect(ENV['DATABASE_URL'])

class Attacks < Sequel::Model
end
