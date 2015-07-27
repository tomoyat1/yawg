require 'bundler'
Bundler.require

require 'sinatra/reloader'
require_relative 'models/init'

class Yawg < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  set :server, :thin
  set :sockets, []
  
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

  post '/game' do
    if params[:existing] == 'true' then
      begin
        if !@@rounds[params[:game]] then
          raise "Group does not exist"
        end
      rescue => evar
        evar.message
      else
        @@rounds[params[:game]].add_player(params[:username])
        session[:username] = @@rounds[params[:game]].players[params[:username]]
        session[:game] = @@rounds[params[:game]]
          settings.sockets.each{|s| s.send(erb :player_list, :layout => false) }
        erb :game do
          erb :staging_existing
        end
      end
    elsif params[:existing] == 'false' then
      begin
        if @@rounds.assoc(params[:game]) then
          raise "Group already exists"
        end
      rescue => evar
        evar.message
      else
        @@rounds.store(params[:game], Round.new(name: params[:game]))
        @@rounds[params[:game]].add_player(params[:username])
        session[:username] = @@rounds[params[:game]].players[params[:username]]
        session[:game] = @@rounds[params[:game]]
        erb :game do
          erb :staging_new
        end
      end
    end
  end

  post '/staging_existing' do
    begin
      if !@@rounds[params[:game]] then
        raise "Group does not exist"
      end
    rescue => evar
      evar.message
    else
      @@rounds[params[:game]].add_player(params[:username])
      session[:username] = @@rounds[params[:game]].players[params[:username]]
      session[:game] = @@rounds[params[:game]]
      settings.sockets.each{|s| s.send(erb :player_list, :layout => false) }
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
      @@rounds.store(params[:game], Round.new(name: params[:game]))
      @@rounds[params[:game]].add_player(params[:username])
      session[:username] = @@rounds[params[:game]].players[params[:username]]
      session[:game] = @@rounds[params[:game]]
      erb :staging_new
    end
  end

  get '/players/list' do
   if !request.websocket?
     halt 500
   else
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
      end
      ws.onclose do
        settings.sockets.delete(ws)
      end
    end
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
