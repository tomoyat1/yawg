module Role
  class GenericRole

    @@desendants = Array.new

    attr_reader :name
    attr_accessor :owner
    attr_reader :player_list_f
    attr_reader :day_action_name
    attr_reader :night_action_name
    attr_reader :night_action_auto
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
      @night_action_auto = false
      @divine_result = '市民'
      @is_count_evil = false
      @is_side_evil = false
    end

    def add_player(player)
      @players << player.name
    end

    def role_msg
      role_msg = "あなたの役職は#{@name}です。"
    end

    def stage_action(target:)
      @action_queue << target
    end

    def execute_actions
      #stub
    end

    def night_action_direct?
      @night_action_direct
    end

    def divine
      @divine_result
    end

    def reset_state
      @action_queue = Array.new
    end

    def release_owner
      @owner = nil
    end
  end
end
