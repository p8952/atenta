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
end
