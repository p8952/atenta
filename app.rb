require 'aws-sdk'
require 'logger'
require 'net/scp'
require 'net/ssh'
require 'sequel'
require 'sinatra/base'

require_relative 'lib/attacks'
require_relative 'lib/aws'
require_relative 'lib/models'

class AttackDashboard < Sinatra::Base
	get '/' do
		redirect to('/attacks')
	end

	get '/attacks' do
		erb :attacks
	end
end
