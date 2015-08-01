module Phase
  class GenericPhase

    #in @action_hash, key is Player doing the action, value is target Player.
    attr_reader :action_queue
    attr_reader :index

    def initialize(index)
      @index = index
      @action_queue = Array.new
    end

    def shown_name
      self.class.name.split('::').last || ''
    end

    def add_action(player:, target:, **args)
      action_descriptor = { player: player, target: target }
      args.each {|key, value| action_descriptor.store(key, value) }
      @action_queue << action_descriptor
    end

    def current_action_name_of_player(player)
      player.role.day_action_name
    end

    def realtime_action_handler(player:, data:)
      #stub
    end

  end
end
