require 'bundler'
Bundler.require

require 'sinatra/reloader'
require 'json'
require_relative 'models/init'

class Yawg < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  set :server, :thin
  set :sockets, Hash.new
  
  set :assets_precompile, %w(application.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  set :assets_css_compressor, :sass
  register Sinatra::AssetPipeline
  settings.sprockets.append_path 'bower_components'

  disable :sessions
  use Rack::Session::Pool

  @@rounds = Hash.new

  get '/' do
    if session[:username] then
      'Session already exists'
    else
      erb :index, :locals => { :location => 'Top' }
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

        session[:username] = params[:username]
        session[:game] = params[:game]

        settings.sockets[params[:game]].each do |username, s| 
          s.send ({ player_list: erb(:player_list,
              :layout => false,
              :locals => {:players => @@rounds[session[:game]].players }) }.to_json)
        end
        info = :info_existing
        controls = :controls_staging_existing
      end
    elsif params[:existing] == 'false' then
      begin
        if @@rounds.key?(params[:game]) then
          raise 'Group already exists'
        end
      rescue => evar
        evar.message
      else
        @@rounds.store(params[:game], Round.new(name: params[:game]))
        @@rounds[params[:game]].add_player(params[:username])

        session[:username] = params[:username]
        session[:game] = params[:game]

        info = :info_new
        controls = :controls_staging_new
      end
    end
    players = @@rounds[session[:game]].players
    erb :game, :locals => { :location => 'Game',
                            :info => info,
                            :controls => controls,
                            :players => @@rounds[session[:game]].players }
  end

  get '/game/status' do
    unless request.websocket?
     halt 500
    else
      request.websocket do |ws|
        ws.onopen do
          unless settings.sockets.key?(session[:game]) then
            settings.sockets.store(session[:game], Hash.new)
          end
          settings.sockets[session[:game]].store(session[:username], ws)
        end
        ws.onmessage do |msg|
          #parse whatever json that gets thrown at us
          msg_hash = JSON.parse(msg)
          if msg_hash.assoc('command') then
            if msg_hash['command'] == 'start' then
              role_count = msg_hash['role_count']
              @@rounds[session[:game]].init_round(role_count)
              settings.sockets[session[:game]].each do |username, s|
                s.send({ phase: 'Day', 
                         role: @@rounds[session[:game]].player(username).role.role_name }.to_json)
              end
            end
          end
        end
        ws.onclose do
          settings.sockets[session[:game]].delete(ws)
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
