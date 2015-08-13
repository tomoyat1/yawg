module Role
  class GenericRole

    @@desendants = Array.new

    attr_reader :name
    attr_accessor :owner
    attr_reader :is_count_evil
    attr_reader :is_side_evil

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
      @day_action_name = '投票する'
      @night_action_name = nil
      @player_list_f = :player_list
      @night_action_direct = false
      @divine_result = '市民'
      @is_count_evil = false
      @is_side_evil = false
    end

    def add_player(player)
      @players << player.name
    end

    def player_list_f
      @player_list_f
    end

    def night_action_direct?
      @night_action_direct
    end

    def day_action_name
      @day_action_name
    end

    def night_action_name
      @night_action_name
    end

    def stage_action(target:)
      @action_queue << target
    end

    def execute_actions
      #stub
    end

    def divine
      @divine_result
    end

  end
end
