require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    def add_action(player:, target:)
      result = Hash.new
      result_str = ''
      if @action_confirmed.index( player.name ) == nil then
        unless player.role.night_action_direct? then
          @action_queue << { player: player, target: target }
          result_str = player.role.indirect_confirm_string
        else
          player.role.stage_action target: target 
          result_str = player.role.execute_actions
        end
        result.store :player, player
        result.store :target, target
        result.store :msg, result_str
        @action_confirmed << player.name
      end 
      result
    end

    def execute_non_imediate_actions
      
    end

    def current_action_name_of_player(player)
      player.role.night_action_name
    end

    def realtime_action_handler(player:, data:)
      if player.role == owner.roles['Werewolf'] then
        target = owner.roles['Werewolf'].update_hitlist( player_name: player.name,
                                                   target_name: data[:target],
                                                   score: data[:score] )
        target
      end
    end
  end
end
