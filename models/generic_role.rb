module Role
  class GenericRole

    @@desendants = Array.new

    attr_reader :name
    attr_accessor :owner

    def self.inherited(child)
      @@desendants << child
    end

    def self.desendants
      @@desendants
    end

    def self.class_name
      self.name.split('::').last || ''
    end

    def initialize
      @players = Array.new
      @action_queue = Array.new
    end

    def add_player(player)
      @players << player.name
    end

    def player_list_f
      'noselect'
    end

    def day_action_name
      "Vote to kill player"
    end

    def night_action_name
      nil
    end

    def stage_action(target:)
      @action_queue << target
    end

    def execute_actions
      @action_queue = Array.new
    end

    def divine
      "Villager side"
    end
  end
end
