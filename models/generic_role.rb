require 'singleton'

module Role
  class GenericRole

    include Singleton

    @@desendants = Array.new

    attr_reader :name

    def self.inherited(child)
      @@desendants << child
    end

    def self.desendants
      @@desendants
    end

    def initialize
      @players = Array.new
      @day_action_queue = Hash.new
      @night_action_queue = Hash.new
    end

    def add_player(player)
      @players << player.name
      if player.role == Werewolf.instance then
        return 'quadstate'
      end
    end

    def day_action_name
      "Vote to kill player"
    end

    def night_action_name
      nil
    end
  end
end
