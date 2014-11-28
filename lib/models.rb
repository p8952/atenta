DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/database.sqlite3')

class Attacks < Sequel::Model
end
