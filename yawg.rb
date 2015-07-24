require 'bundler'
Bundler.require

require 'sinatra/base'
require 'sinatra/asset_pipeline'
require 'sprockets'
require 'bower'

require_relative 'models/init'

class Yawg < Sinatra::Base
  
  set :assets_precompile, %w(application.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  set :assets_css_compressor, :sass
  register Sinatra::AssetPipeline
  settings.sprockets.append_path 'bower_components'

  enable :sessions

  @@rounds = Hash.new

  get '/' do
    erb :index
  end

  post '/staging_existing' do
    @@rounds[params[:game]].add_player(params[:username])
    erb :staging_existing
  end

  post '/staging_new' do
    @@rounds.store(params[:game], Round.new)
    @@rounds[params[:game]].add_player(params[:username])
    erb :staging_new
  end



# Routing for development. Everything below is temporary.
  get '/new/game/:game_name' do
    added = @@rounds.store(params[:game_name], Round.new) 
  end

  get '/new/player/:name' do
  end

  get '/round/start/:game' do
    @@rounds[params[:game]].init_round( Villager: 3, Werewolf: 1 )
  end
  
  run! if app_file == $0
end
