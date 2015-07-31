require 'observer'

require_relative 'generic_role'
require_relative 'villager'
require_relative 'werewolf'
require_relative 'generic_phase'
require_relative 'day'
require_relative 'night'

require_relative '../ws_controller'

include Role
include Phase

class Round

  include Observable

  attr_accessor :players
  attr_reader :name
  attr_reader :phases

  def initialize(name:)
    @name = name
    @players = Hash.new
    @phases = Array.new
  end

  def add_player(name)
    unless @players.key?(name) then
      @players.store(name, Player.new(name: name))
      changed
      notify_observers players: @players, round: self, players_changed: true
    else
      raise "Player already in group"
    end
  end

  def player(name)
    @players[name]
  end

  def init_round(role_hash)
    @phases << Night.new(1)

    role_array = Array.new
    role_hash.each do |key, value|
      value.times do
        role_array << key
      end
    end
    if role_array.size < @players.size then
      until role_array.size == @players.size
        role_array << "Villager" 
      end
    end
    role_array.shuffle!
    @players.values.each_index do |i|
      @players.values[i].role = Role.const_get(role_array[i]).instance
    end
    
    changed
    notify_observers players: @players, round: self, round_start: true
  end

  def action_name_of_player(player)
    @phases.last.current_action_name_of_player(player)
  end

  def add_action_to_queue(hash)
  end

  def realtime_handler(player_name:, data:)
    if @players[player_name].role == Werewolf.instance then
      target = Werewolf.instance.update_hitlist(player_name: player_name,
                                       target: data[:target],
                                       score: data[:score])
      changed
      notify_observers(players: @players,
                       round: self,
                       werewolf_realtime: true,
                       changed: target)
    end
  end
end
