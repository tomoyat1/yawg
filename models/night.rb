require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    def initialize(index)
      super
      @shown_name = "夜"
      @clock = 3
      @start_msg = "夜が来ました。能力を発動する相手を選んでください。全員が行動を確定した時点で自動的に昼になります。"
      @timeup_msg = "選択時間は終了しました。"
    end

    def add_action(player:, targets:)
      result = Hash.new
      result_str = ''
      if @action_confirmed.index( player.name ) == nil then
        targets_valid = true
        targets.each do |target|
          if target and !target.is_alive then
            targets_valid = false
          end
        end
        if targets[0] == nil && !player.role.night_action_auto && targets_valid then
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
      role_hash['Knight'].execute_actions
      role_hash['Werewolf'].execute_actions
      return :proceed
    end

    def current_action_name_of_player(player)
      player.role.night_action_name
    end

    def did_everyone_confirm?
      did_everyone_confirm = true
      owner.players.each_key do |player_name|
        unless @action_confirmed.index( player_name ) then
          did_everyone_confirm = false
        end
      end
      return did_everyone_confirm
    end

    def realtime_action_handler(player:, data:)
      if @action_confirmed.index( player.name ) == nil then
        if player.role == owner.roles['Werewolf'] then
          target = owner.roles['Werewolf'].update_hitlist( player_name: player.name,
                                                     target_name: data[:target],
                                                     score: data[:score] )
          target
        end
      else
        return nil
      end
    end
  end
end
