module Phase
  class GenericPhase

    attr_reader :action_queue
    attr_reader :index
    attr_accessor :owner

    def initialize(index)
      @index = index
      @action_queue = Array.new
      @action_confirmed = Array.new
    end

    def shown_name
      self.class.name.split('::').last || ''
    end

    def add_action(player:, target:)
      #stub
    end

    def current_action_name_of_player(player)
      player.role.day_action_name
    end

    def realtime_action_handler(player:, data:)
      #stub
    end

  end
end
