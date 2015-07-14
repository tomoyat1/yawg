require 'sinatra/base'
require_relative 'models/init'

class Yawg < Sinatra::Base
  @@round = Round.new

  get '/' do
    "Hello werewolf world!"
  end

  get '/new/player/:name' do
    added = @@round.add_player(params['name'])
    added + ' added'
  end

  get '/round/start' do
    @@round.init_round( Villager: 3, Werewolf: 1 )
    message = ""
    @@round.players.each do |player|
      message << player.role.to_s
    end
    message
  end
  
  run! if app_file == $0
end
