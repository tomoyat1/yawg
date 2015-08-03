require 'singleton'

module Role
  class Diviner < GenericRole
    
    include Singleton

    def initialize
      @name = "Diviner"
      super
    end

    def player_list_f
      'singleselect'
    end

    def action_instant?
      true
    end

    def night_action_name
      "Divine"
    end

    def execute_actions
      divine = @action_queue.last.divine
      super
      divine
    end
  end
end
