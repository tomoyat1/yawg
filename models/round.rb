require_relative 'generic_role'
require_relative 'villager'
require_relative 'werewolf'
require_relative 'generic_phase'
require_relative 'day'
require_relative 'night'

include Role
include Phase

class Round
  attr_accessor :players

  def initialize
    @players = Hash.new
  end

  def add_player(name)
    @players.store(name.intern, Player.new(name: name))
    @players.values.last.name
  end

  def init_round(role_hash)
    role_array = Array.new
    role_hash.each do |key, value|
      value.times do
        role_array << key.id2name
      end
    end
    role_array.shuffle!
    role_array.each_index do |i|
      @players[i].role = Role.const_get(role_array[i])
    end
  end

  def add_action_to_queue(hash)
    @phase
  end

end
