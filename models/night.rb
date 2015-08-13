require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    def add_action(player:, targets:)
      result = Hash.new
      result_str = ''
      if @action_confirmed.index( player.name ) == nil then
        if targets[0] == nil then
          result_str = '能力を発動する相手を選んでください。'
        else
          unless player.role.night_action_direct? then
            targets.each do |target|
              @action_queue << { player: player, target: target }
            end
            result_str = player.role.indirect_confirm_string
          else
            targets.each do |target|
              player.role.stage_action target: target 
            end
            result_str = player.role.execute_actions
          end
          @action_confirmed << player.name
        end
        result.store :player, player
        result.store :msg, result_str
      end 
      result
    end

    def execute_non_imediate_actions
      super
      role_hash = owner.roles
      #role_hash['Knight'].execute_actions
      role_hash['Werewolf'].execute_actions
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
