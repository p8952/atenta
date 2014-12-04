require 'aws-sdk'
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
	get '/' do
		erb :home
	end

	get '/api/:start_time/:end_time' do
		start_time = Time.strptime(params[:start_time], '%s')
		end_time = Time.strptime(params[:end_time], '%s')
		puts Attacks.where(:timestamp => start_time..end_time).to_json
		Attacks.where(:timestamp => start_time..end_time).to_json
	end
end
