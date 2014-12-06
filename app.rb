require 'aws-sdk'
require 'geoip'
require 'logger'
require 'net/scp'
require 'net/ssh'
require 'pmap'
require 'sequel'
require 'sinatra/base'

require_relative 'lib/attacks'
require_relative 'lib/aws'
require_relative 'lib/models'

class Atenta < Sinatra::Base
	Thread.new do
		loop do
			harvest_honeypots
			populate_attacks
		end
	end

	get '/' do
		erb :home
	end

	get '/attacks' do
		start_time = Time.at(Time.now.to_i - 30)
		end_time = Time.now
		Attacks.where(:timestamp => start_time..end_time).to_json
	end
end
