require 'bundler'
Bundler.require

require_relative 'models/init'

class Yawg < Sinatra::Base
  
  set :assets_precompile, %w(application.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  set :assets_css_compressor, :sass
  register Sinatra::AssetPipeline
  settings.sprockets.append_path 'bower_components'

  enable :sessions

  @@rounds = Hash.new

  get '/' do
    if session[:username] then
      "Session already exists"
    else
      erb :index
    end
  end

  post '/staging_existing' do
    begin
      if !@@rounds[params[:game]] then
        raise "Group does not exist"
      end
      @@rounds[params[:game]].add_player(params[:username])
    rescue => evar
      evar.message
    else
      session[:username] = params[:username]
      session[:game] = params[:game]
      erb :staging_existing
    end
  end

  post '/staging_new' do
    begin
      if @@rounds.assoc(params[:game]) then
        raise "Group already exists"
      end
    rescue => evar
      evar.message
    else
      @@rounds.store(params[:game], Round.new)
      @@rounds[params[:game]].add_player(params[:username])
      session[:username] = params[:username]
      session[:game] = params[:game]
      erb :staging_new
    end
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
