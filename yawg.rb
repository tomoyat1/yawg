require 'sinatra/base'
require_relative 'models/init'

class Yawg < Sinatra::Base
  @@round = Round.new

  get '/' do
    "Hello werewolf world!"
  end

  get '/new/player/:name' do
    added = @@round.add_player(params['name'])
  end
  
  run! if app_file == $0
end
