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
  
  set :assets_precompile, %w(index.js round.js application.css *.png *.jpg *.svg *.eot *.ttf *.woff)
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
    session.delete :wrong_passcode
    session.delete :round_gone
    if params[:username] && params[:round] then
      if params[:existing] == 'true' then
        if @@rounds[params[:round]] then
          add_result = @@rounds[params[:round]].add_player(params[:username], params[:passcode] )
          if add_result == :success then
            set_session
            redirect to('/round'), 303
          elsif add_result == :conflict
            if session[:username] then
              redirect to('/round'), 303
            else
              session[:p_conflict] = params[:username]
              redirect to('/')
            end
          elsif add_result == :wrong_passcode then
            session[:wrong_passcode] = true
            redirect to('/')
          end
        else
          session[:no_round] = true
          redirect to('/')
        end
      elsif params[:existing] == 'false' then
        unless @@rounds[params[:round]] then
          @@rounds.store( params[:round], Round.new( name: params[:round], passcode: params[:passcode] ) )
          @@rounds[params[:round]].add_observer WSController.instance
          @@rounds[params[:round]].add_player(params[:username], params[:passcode])
          @@rounds[params[:round]].player(params[:username]).is_host = true
          set_session
          redirect to('/round'), 303
        else
          if session[:username] then
            redirect to('/round'), 303
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
    if session[:username] then
      round = @@rounds[session[:round]]
      if !round then
        exit_round
        session.clear
        session[:round_gone] = true
        redirect to('/')
      elsif !round.in_progress then
        if round.player( session[:username] ).is_host
          send_staging :info_new, :controls_staging_new
        else
          send_staging :info_existing, :controls_staging_existing
        end
      else
        reconnect
      end
    else
      redirect to('/')
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
          puts "#{session[:username]} connected"
        end
        ws.onmessage do |msg|
          msg_hash = JSON.parse msg
          if msg_hash.key?('command') then
            round = @@rounds[session[:round]]
            if msg_hash['command'] == 'start' then
              if @@rounds[session[:round]] then
                role_rand = msg_hash['role_rand']
                role_min = msg_hash['role_min']
                first_kill = msg_hash['first_kill']
                round.init_round role_rand, role_min, first_kill
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
            elsif msg_hash['command'] == 'chat' then
              round.handle_chat_msg player_name: session[:username],
                                    msg: msg_hash['msg'],
                                    room_name: msg_hash['room_name']
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
                                 :no_round => session[:no_round],
                                 :wrong_passcode => session[:wrong_passcode],
                                 :round_gone => session[:round_gone] }
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
                              :player_list => :player_list,
                              :players => players,
                              :roles => @@rounds[session[:round]].roles }
    end

    def reconnect
      round = @@rounds[session[:round]]
      unless round.done then
        player = round.player session[:username]
        info = format_info "#{session[:round]}に再接続しました。"
        phase = round.current_phase.shown_name
        player_list = round.current_phase.get_player_list player
        pl_without_self = round.players.reject {|key, value| value == player }
        erb :round_reconnect,
                   :locals => { :location => session[:round],
                                :info => :info_reconnected,
                                :phase => phase,
                                :controls => :controls_round,
                                :action_name => round.action_name_of_player( player ),
                                :player_list => player_list,
                                :players => pl_without_self }
      else
        exit_round
        session.clear
        session[:round_gone] = true
        redirect to('/')
      end
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
