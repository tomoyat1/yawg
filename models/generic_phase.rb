module Phase
  class GenericPhase

    #in @action_hash, key is Player doing the action, value is target Player.
    attr_reader :action

    def initialize
      @action_hash = Hash.new
    end

    def add_action(hash)
      @action_hash.store(hash[:player], hash[:target])
    end

  end
end
