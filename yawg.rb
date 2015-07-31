require 'bundler'
Bundler.require

require 'sinatra/reloader'
require 'json'
require_relative 'models/init'

require_relative 'ws_controller'

class Yawg < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  set :server, :thin
  
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
        @@rounds[params[:game]].add_observer(WSController.instance)
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
          WSController.instance.add_socket( ws, session[:username], session[:game] )
        end
        ws.onmessage do |msg|
          msg_hash = JSON.parse(msg)
          if msg_hash.key?('command') then
            round = @@rounds[session[:game]]
            if msg_hash['command'] == 'start' then
              role_count = msg_hash['role_count']
              round.init_round(role_count)

            elsif msg_hash['command'] == 'quad_state_score' then
              extracted_score = { target: msg_hash['target'],
                                  score: msg_hash['score'] }
              round.realtime_handler(player_name: session[:username],
                                     data: extracted_score)
            end
          end
        end
        ws.onclose do
          WSController.instance.delete_socket(session[:username], session[:game]) 
          session.clear
        end
      end
    end
  end

  helpers do
    def format_info(raw_string)
      "<div>#{raw_string}</div>"
    end
  end

# Routing for development. Everything below is temporary.

# Oops, spoke too soon. Below is NOT temporary.
  run! if app_file == $0
end
