require_relative 'generic_role'
require_relative 'villager'
require_relative 'werewolf'
include Role


class Round
  attr_accessor :players

  def initialize
    @players = Array.new
  end

  def add_player(name)
    @players << Player.new(name: name)
    @players.last.name
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
end
