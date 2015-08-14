require 'bundler'
Bundler.require

require 'sinatra/reloader'
require 'json'
require_relative 'models/init'

require_relative 'ws_controller'

class Yawg < Sinatra::Base

  set :environment, :development

  configure :development do
    register Sinatra::Reloader
  end

  set :server, 'thin'
  
  set :assets_precompile, %w(application.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  set :assets_css_compressor, :sass
  register Sinatra::AssetPipeline
  settings.sprockets.append_path 'bower_components'

  disable :sessions
  use Rack::Session::Pool

  @@rounds = Hash.new

  get '/' do
    login
  end

  post '/round' do
    if params[:existing] == 'true' then
      begin
        if !@@rounds[params[:round]] then
          raise "Group does not exist"
        end
      rescue => evar
        return evar.message
      else
        @@rounds[params[:round]].add_player(params[:username])

        session[:username] = params[:username]
        session[:round] = params[:round]

        info = :info_existing
        controls = :controls_staging_existing
      end
    elsif params[:existing] == 'false' then
      begin
        if @@rounds.key?( params[:round] ) then
          raise 'Group already exists'
        end
      rescue => evar
        return evar.message
      else
        @@rounds.store( params[:round], Round.new( name: params[:round] ) )
        @@rounds[params[:round]].add_observer(WSController.instance)
        @@rounds[params[:round]].add_player(params[:username])

        session[:username] = params[:username]
        session[:round] = params[:round]

        info = :info_new
        controls = :controls_staging_new
      end
    end
    players = @@rounds[session[:round]].players
    erb :round, :locals => { :location => session[:round],
                            :info => info,
                            :controls => controls,
                            :players => players,
                            :roles => @@rounds[session[:round]].roles }
  end

  get '/round' do
  end

  get '/round/list' do
    erb :round_list, :layout => false, :locals => { :rounds => @@rounds.keys }
  end

  get '/round/status' do
    unless request.websocket?
      halt 500
    else
      request.websocket do |ws|
        ws.onopen do
          WSController.instance.add_socket( ws, session[:username], session[:round] )
        end
        ws.onmessage do |msg|
          msg_hash = JSON.parse msg
          if msg_hash.key?('command') then
            round = @@rounds[session[:round]]
            if msg_hash['command'] == 'start' then
              role_count = msg_hash['role_count']
              round.init_round role_count
            elsif msg_hash['command'] == 'quad_state_score' then
              extracted_score = { target: msg_hash['target'],
                                  score: msg_hash['score'] }
              round.realtime_handler( player_name: session[:username],
                                      data: extracted_score )
            elsif msg_hash['command'] == 'confirm_action' then
              round.add_action_to_phase_queue player_name: session[:username],
                                              target_names: msg_hash['targets']
            end
          end
        end
        ws.onclose do
          puts "#{session[:username]}'s connection was terminated."
          WSController.instance.delete_socket(session[:username], session[:round]) 
        end
      end
    end
  end

  get '/round/exit' do
    @@rounds.reject!{ |key, value| key == session[:round] }
    puts "Released round #{session[:round]}"
    session.clear
    '<script>window.location = "/"</script>'
  end

  helpers do
    def login
      if session[:username] then
        erb :reconnect, :locals => { :location => 'Reconnect', :round => session[:round] }
      else
        erb :index, :locals => { :location => 'Top' }
      end
    end

    def format_info(raw_string)
      "<div>#{raw_string}</div>"
    end
  end

# Routing for development. Everything below is temporary.

# Oops, spoke too soon. Below is NOT temporary.
  run! if app_file == $0
end
