module Role
  class Diviner < GenericRole
    
    def initialize
      @name = "Diviner"
      super
    end

    def player_list_f
      'singleselect'
    end

    def night_action_direct?
      true
    end

    def night_action_name
      "Divine"
    end

    def execute_actions
      divine = @action_queue.last.divine
      name = @action_queue.last.name
      super
      msg = "#{name}を占った結果#{divine}でした。"
    end
  end
end
