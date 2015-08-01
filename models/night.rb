require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    def execute_actions
      @action_queue.each do |action_descriptor|
        
      end
    end

    def current_action_name_of_player(player)
      player.role.night_action_name
    end

    def realtime_action_handler(player:, data:)
      if player.role == Werewolf.instance then
        target = Werewolf.instance.update_hitlist(player_name: player.name,
                                         target: data[:target],
                                         score: data[:score])
        target
      end
    end
  end
end
