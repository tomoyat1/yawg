require 'singleton'
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
    @sockets[round_name].delete username
  end

  def add_to_next_msg(key:, value:)
    unless @next_msg then
      @next_msg = Hash.new
    end
    @next_msg.store(key, value)
  end

  def send_msg_to_player_in_game(msg: @next_msg, player:, game:)
    if @sockets[game.name].key?(player.name) then
      @sockets[game.name][player.name].send(msg.to_json)
    end
    if msg == @next_msg then
      @next_msg = nil
    end
  end

  def queue_erb(file_key, msg_key:, locals: {})
    file_path = "views/#{file_key.id2name}.erb"
    template = Tilt.new(file_path)
    rendered_string = template.render(self, locals)
    add_to_next_msg(key: msg_key, value: rendered_string)
  end

  def update(players:, round:, **args)
    if args[:players_changed] and @sockets.size != 0 then
      send_player_list(players, round)
    elsif args[:round_start] then
      send_game_ui(players, round)
    elsif args[:werewolf_realtime] then
      send_hit_list_w(players, round, args[:changed])
    end
  end

  private
  def send_player_list(players, round)
    players.each_value do |player|
      add_to_next_msg(key: :action, value: 'pl_in_staging')
      queue_erb(:player_list,
                msg_key: :player_list,
                locals: { players: round.players })
      send_msg_to_player_in_game( player: player, game: round )
    end
  end

  def send_game_ui(players, round)
    players.each_value do |player|
      add_to_next_msg( key: :action, value: 'in_game' )
      add_to_next_msg( key: :phase, value: round.phases.last.shown_name )
      
      role_msg = format_info "Your role is #{player.role.name}"
      add_to_next_msg( key: :info, value: role_msg )
      queue_erb( :controls_game, msg_key: :controls, 
                          locals: { action_name: round.action_name_of_player(player) } )

      if player.player_list_f == 'quadstate' then
        player_list = :player_list_with_selections_quadstate
      else
        player_list = :player_list_with_selections
      end
      queue_erb( player_list, msg_key: :players,
                          locals: { players: round.players } )

      send_msg_to_player_in_game( player: player, game: round )

    end
  end

  def send_hit_list_w(players, round, changed)
    players.each_value do |player|
      if player.role == Werewolf.instance then
        add_to_next_msg( key: :action, value: 'quad_state_score' )
        add_to_next_msg( key: :player, value: changed )
        new_score = Werewolf.instance.realtime_hitlist[changed]['total']
        add_to_next_msg( key: :score, value: new_score )
        send_msg_to_player_in_game( player: player, game: round )
      end
    end
  end

  def format_info(raw_string)
    "<div>#{raw_string}</div>"
  end

end
