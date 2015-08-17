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

  set :server, 'thin'
  
  set :assets_precompile, %w(application.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  set :assets_css_compressor, :sass
  register Sinatra::AssetPipeline
  settings.sprockets.append_path 'bower_components'

  disable :sessions
  use Rack::Session::Pool, :expire_after => 2592000

  @@rounds = Hash.new

  get '/' do
    login
  end

  post '/round' do
    session.delete :p_conflict
    session.delete :r_conflict
    session.delete :no_round
    if params[:username] && params[:round] then
      if params[:existing] == 'true' then
        if @@rounds[params[:round]] then
          if @@rounds[params[:round]].add_player(params[:username]) then
            set_session
            send_staging :info_existing, :controls_staging_existing
          else
            "adding player to round failed"
            if session[:username] then
              redirect to('/')
            else
              session[:p_conflict] = params[:username]
              redirect to('/')
            end
          end
        else
          session[:no_round] = true
          redirect to('/')
        end
      elsif params[:existing] == 'false' then
        unless @@rounds[params[:round]] then
          @@rounds.store( params[:round], Round.new( name: params[:round] ) )
          @@rounds[params[:round]].add_observer(WSController.instance)
          @@rounds[params[:round]].add_player(params[:username])
          @@rounds[params[:round]].player(params[:username]).is_host = true
          set_session
          send_staging :info_new, :controls_staging_new
        else
          if session[:username] then
            redirect to('/')
          else
            session[:r_conflict] = params[:round]
            redirect to('/')
          end
        end
      end
    else
      redirect to('/'), "フォームが不正です"
    end
  end

  get '/round' do
    round = @@rounds[session[:round]]
    if round then
      if round.player( session[:username] ).is_host
        send_staging :info_reconnected, :controls_staging_new
      else
        send_staging :info_reconnected, :controls_staging_existing
      end
    else
      exit_round
      session.clear
      redirect to('/'), 'ゲームは終了しています。'
    end
  end

  get '/round/list' do
    joinable_rounds = @@rounds.reject {|key, value| value.in_progress }
    erb :round_list, :layout => false, :locals => { :rounds => joinable_rounds.keys }
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
              if @@rounds[session[:round]] then
                role_count = msg_hash['role_count']
                round.init_round role_count
              else
                WSController.instance.send_msg_to_socket ws, "ゲームは削除されました。ゲームから抜けてください。"
              end
            elsif msg_hash['command'] == 'quad_state_score' then
              extracted_score = { target: msg_hash['target'],
                                  score: msg_hash['score'] }
              round.realtime_handler( player_name: session[:username],
                                      data: extracted_score )
            elsif msg_hash['command'] == 'confirm_action' then
              round.add_action_to_phase_queue player_name: session[:username],
                                              target_names: msg_hash['targets']
            elsif msg_hash['command'] == 'extend' then
              round.current_phase.extend_phase 1
            elsif msg_hash['command'] == 'skip' then
              round.current_phase.skip_remaining_time
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
    exit_round
    session.clear
    redirect to('/')
  end

  helpers do
    def login
      if session[:username] then
        erb :reconnect, :locals => { :location => 'Reconnect', :round => session[:round] }
      else
        erb :index, :locals => { :location => 'Top',
                                 :p_conflict => session[:p_conflict],
                                 :r_conflict => session[:r_conflict],
                                 :no_round => session[:no_round] }
      end
    end
    
    def set_session
      session[:username] = params[:username]
      session[:round] = params[:round]
    end

    def send_staging(info, controls)
      players = @@rounds[session[:round]].players
      erb :round, :locals => { :location => session[:round],
                              :info => info,
                              :controls => controls,
                              :players => players,
                              :roles => @@rounds[session[:round]].roles }
    end

    def exit_round
      round = @@rounds[session[:round]]
      if round then
        round.players.delete session[:username]
        if round.players.empty? then
          @@rounds.delete session[:round]
          RoundCleaner.instance.release session[:round]
        end
      end
    end

    def format_info(raw_string)
      "<div>#{raw_string}</div>"
    end

  end

# Routing for development. Everything below is temporary.

# Oops, spoke too soon. Below is NOT temporary.
  run! if app_file == $0

  def self.delete_round(round_name)
    @@rounds.delete round_name
  end

  def self.send_msg_to_round(round_name, msg)
    round = @@rounds[round_name]
    if round.class == Round then
      round.message msg
    end
  end
end
