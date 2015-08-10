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
  attr_reader :roles

  def initialize(name:)
    @name = name
    @players = Hash.new
    @phases = Array.new
    @roles = Hash.new

    GenericRole.desendants.each{|desendant| add_role(desendant.new) }
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

  def current_phase
    @phases.last
  end

  def add_phase(phase)
    phase.owner = self
    @phases << phase
  end

  def add_role(role)
    role.owner = self
    @roles.store(role.class.class_name, role)
  end

  def init_round(role_hash)
    add_phase Night.new(1)

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
      @players.values[i].role = @roles[role_array[i]]
    end
    
    changed
    notify_observers players: @players, round: self, round_start: true
    current_phase.start_phase
  end

  def next_phase
    current_phase.end_phase
    @roles['Werewolf'].reset_state
    #@roles['Knight'].reset_state
    if current_phase.class == Night then
      add_phase Day.new( current_phase.index )
    else
      add_phase Night.new( current_phase.index + 1 )
    end

    current_phase.start_phase
    alive = @players.select {|key, value| value.is_alive }
    changed
    notify_observers players: alive, round: self, next_phase: true

    dead = @players.select {|key, value| !value.is_alive }
    changed
    notify_observers players: dead, round: self, spirit_world: true
  end

  def action_name_of_player(player)
    current_phase.current_action_name_of_player( player )
  end

  def add_action_to_phase_queue(pt_pair)
    result = Hash.new
    pt_pair.each do |player_name, target_name|
      unless target_name == '' then
        result = current_phase.add_action player: player( player_name ),
                                          target: player( target_name )
      end
    end
    changed
    notify_observers players: @players, round: self, add_action: true, result: result
  end

  def realtime_handler(player_name:, data:)
      target = current_phase.realtime_action_handler( player: player( player_name ),
                                                      data: data )
      changed
      notify_observers players: @players,
                       round: self,
                       werewolf_realtime: true,
                       changed: target
  end

  def message(msg)
    changed
    notify_observers players: @players,
                     round: self,
                     timer_message: true,
                     msg: msg
  end
end
