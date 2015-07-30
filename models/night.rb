require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    def execute_actions
      @action_hash.each do |key, value|
         key.execute_action(value)
      end
    end

    def current_action_name_of_player(player)
      player.role.night_action_name
    end
  end
end
