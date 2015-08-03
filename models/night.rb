require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    def add_action(player:, target:)
      result = Hash.new
      if @action_confirmed.index( player.name ) == nil then
        unless player.role.action_instant? then
          @action_queue << { player: player, target: target }
        else
          player.role.stage_action( target: target )
          result_str = player.role.execute_actions
          result.store( :player, player )
          result.store( :target, target )
          result.store( :role, result_str )
        end
        @action_confirmed << player.name
      end 
      result
    end

    def current_action_name_of_player(player)
      player.role.night_action_name
    end

    def realtime_action_handler(player:, data:)
      if player.role == Werewolf.instance then
        target = Werewolf.instance.update_hitlist( player_name: player.name,
                                                   target: data[:target],
                                                   score: data[:score] )
        target
      end
    end
  end
end
