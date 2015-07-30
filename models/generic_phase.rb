module Phase
  class GenericPhase

    #in @action_hash, key is Player doing the action, value is target Player.
    attr_reader :action_hash
    attr_reader :index

    def initialize(index)
      @action_hash = Hash.new
      @index = index
    end

    def shown_name
      self.class.name.split('::').last || ''
    end

    def add_action(hash)
      @action_hash.store(hash[:player], hash[:target])
    end

    def current_action_name_of_player(player)
      puts "is superclass"
      player.role.day_action_name
    end

  end
end
