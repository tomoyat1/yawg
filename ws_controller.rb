require 'singleton'
require 'sass'
require 'tilt'

class WSController

  include Singleton
  include Role

  attr_reader :sockets

  def initialize
    @sockets = Hash.new
    @next_msg = nil
  end

  def add_socket(ws, player_name, round_name)
    unless @sockets.key?(round_name) then
      @sockets.store(round_name, Hash.new)
    end
    @sockets[round_name].store(player_name, ws)
  end

  def delete_socket(username, round_name)
    if @sockets[round_name] then
      @sockets[round_name].delete username
      if @sockets[round_name].empty? then
        @sockets.delete round_name
      end
    end
  end

  def add_to_next_msg(key:, value:)
    unless @next_msg then
      @next_msg = Hash.new
    end
    @next_msg.store(key, value)
  end

  def send_msg_to_player_in_round(msg: @next_msg, player:, round:)
    if @sockets[round.name] && @sockets[round.name].key?(player.name) then
      @sockets[round.name][player.name].send msg.to_json
    end
    if msg == @next_msg then
      @next_msg = nil
    end
  end

  def queue_erb(file_key, msg_key:, locals: {})
    file_path = "views/#{file_key.id2name}.erb"
    template = Tilt.new file_path
    rendered_string = template.render(self, locals)
    add_to_next_msg key: msg_key, value: rendered_string
  end

  def send_reconnect(player:, round:)
    add_to_next_msg key: :action, value: 'in_round'
    add_to_next_msg key: :phase, value: round.current_phase.shown_name
    player_list = round.current_phase.get_player_list player
    pl_without_self = players.reject {|key, value| value == player }
    queue_erb( player_list, msg_key: :players,
                        locals: { players: pl_without_self } )
    queue_erb( :controls_round, msg_key: :controls,
                        locals: { action_name: round.action_name_of_player(player) } )
    send_msg_to_player_in_round player: player, round: round
  end

  def update(players:, round:, **args)
    if args[:players_changed] and @sockets.size != 0 then
      send_player_list players, round
    elsif args[:round_start] then
      send_round_ui players, round
    elsif args[:next_phase] then
      send_phase players, round
    elsif args[:spirit_world] then
      send_spirit_world players, round
    elsif args[:revote] then
      send_revote players, round, args[:candidates]
    elsif args[:round_over] then
      send_round_result players, round, args[:winner_msg], args[:winners], args[:losers]
    elsif args[:werewolf_realtime] then
      send_hit_list_w players, round, args[:changed]
    elsif args[:add_action] then
      send_action_result players, round, args[:result]
    elsif args[:timer_message] then
      send_message players, round, args[:msg]
    elsif args[:round_chat] then
      send_chat_msg players, round, args[:msg]
    elsif args[:force_kill] then
      kill_connections_in_round players, round
    end
  end

  def send_msg_to_socket(socket, msg)
    if @sockets[round.name] && @sockets[round.name].key?(player.name) then
      add_to_next_msg key: :action, value: 'in_round'
      add_to_next_msg key: :info, value: format_info( msg )
      socket.send @next_msg.to_json
      @next_msg = nil
    end
  end

  private
  def send_player_list(players, round)
    players.each_value do |player|
      add_to_next_msg(key: :action, value: 'pl_in_staging')
      queue_erb(:player_list,
                msg_key: :player_list,
                locals: { players: round.players })
      send_msg_to_player_in_round( player: player, round: round )
    end
  end

  def send_round_ui(players, round)
    players.each_value do |player|
      add_to_next_msg( key: :action, value: 'in_round' )
      add_to_next_msg( key: :phase, value: round.phases.last.shown_name )

      role_msg = format_info player.role.role_msg
      add_to_next_msg( key: :info, value: role_msg )
      queue_erb( :controls_round, msg_key: :controls,
                          locals: { action_name: round.action_name_of_player(player) } )

      player_list = round.current_phase.get_player_list player

      pl_without_self = round.players.reject {|key, value| value == player }
      queue_erb( player_list, msg_key: :players,
                          locals: { players: pl_without_self } )

      send_msg_to_player_in_round( player: player, round: round )

    end
  end

  def send_phase(players, round)
    players.each_value do |player|
      add_to_next_msg key: :action, value: 'in_round'
      add_to_next_msg key: :phase, value: round.current_phase.shown_name
      player_list = round.current_phase.get_player_list player
      pl_without_self = players.reject {|key, value| value == player }
      queue_erb( player_list, msg_key: :players,
                          locals: { players: pl_without_self } )
      queue_erb( :controls_round, msg_key: :controls,
                          locals: { action_name: round.action_name_of_player(player) } )
      send_msg_to_player_in_round player: player, round: round
    end
  end

  def send_spirit_world(players, round)
    players.each_value do |player|
      add_to_next_msg key: :action, value: 'spirit'
      add_to_next_msg key: :phase, value: '霊界'
      add_to_next_msg key: :info, value: 'あなたは殺されました。以後霊界からゲームを傍観してください。'
      queue_erb( :player_list, msg_key: :players,
                              locals: { players: round.players } )
      queue_erb( :controls_spirit, msg_key: :controls )
      send_msg_to_player_in_round player: player, round: round
    end
  end

  def send_revote(players, round, candidates)
    players.each_value do |player|
      add_to_next_msg key: :action, value: 'in_round'
      unless candidates.key?( player.name ) then
        queue_erb( :player_list_with_selections, msg_key: :players,
                            locals: { players: candidates } )
        queue_erb( :controls_round, msg_key: :controls,
                            locals: { action_name: round.action_name_of_player(player) } )
      else
        queue_erb( :player_list, msg_key: :players,
                            locals: { players: candidates } )
        queue_erb( :controls_round, msg_key: :controls,
                            locals: { action_name: nil } )
      end
      send_msg_to_player_in_round player: player, round: round
    end
  end

  def send_round_result (players, round, winner_msg, winners, losers)
    players.each_value do |player|
      add_to_next_msg key: :action, value: 'round_result'
      add_to_next_msg key: :phase, value: winner_msg
      queue_erb( :player_list_with_roles, msg_key: :players,
                                          locals: { winners: winners, losers: losers } )
      queue_erb( :controls_results, msg_key: :controls )

      send_msg_to_player_in_round player: player, round: round
    end
  end

  def send_hit_list_w(players, round, changed)
    players.each_value do |player|
      if player.role == round.roles['Werewolf'] then
        add_to_next_msg key: :action, value: 'quad_state_score'
        add_to_next_msg key: :player, value: changed
        target_scores = round.roles['Werewolf'].realtime_hitlist[changed]
        new_score = target_scores['total']
        specifics = target_scores.reject {|key, value| key == 'total' }
        add_to_next_msg key: :score, value: new_score
        add_to_next_msg key: :specifics, value: specifics
        send_msg_to_player_in_round player: player, round: round
      end
    end
  end

  def send_action_result(players, round, result)
    unless result.empty? then
      add_to_next_msg key: :action, value: 'in_round'
      add_to_next_msg key: :info, value: format_info( result[:msg] )
      send_msg_to_player_in_round player: result[:player], round: round
    end
  end

  def send_message(players, round, msg)
    players.each_value do |player|
      add_to_next_msg key: :action, value: 'in_round'
      add_to_next_msg key: :info, value: format_info( msg )
      send_msg_to_player_in_round player: player, round: round
    end
  end

  def send_chat_msg(players, round, msg)
    players.each_value do |player|
      add_to_next_msg key: :action, value: 'chat'
      add_to_next_msg key: :msg, value: msg
      send_msg_to_player_in_round player: player, round: round
    end
  end

  def kill_connections_in_round(players, round)
    @sockets[round.name].each do |username, socket|
      socket.close
      @sockets[round.name].delete username
    end
    @sockets.delete round.name
  end

  def format_info(raw_string)
    "<div>#{raw_string}</div>"
  end
end
