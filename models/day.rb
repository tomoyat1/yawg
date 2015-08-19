require_relative 'generic_phase'

module Phase
  class Day < GenericPhase

    def initialize(index)
      super
      @shown_name = "昼"
      @clock = 5
      @start_msg = "朝が来ました。処刑する人を相談して決めて、各自投票をしてください。"
      @timeup_msg = "相談と投票の時間は終了しました。"

    end

    def add_action(player:, targets:)
      result = Hash.new
      result_str = ''
      if @action_confirmed.index( player.name ) == nil then
        unless targets[0] == nil then
          @action_queue << targets.first
          result_str = '投票を受け付けました。'
        else
          result_str = '投票する人を選んでください。'
        end
      end
      @action_confirmed << player.name
      result.store :player, player
      result.store :msg, result_str
      result
    end

    def execute_non_imediate_actions
      vote_results = Hash.new
      @action_queue.each do |vote|
        unless vote_results.key?( vote.name ) then
          vote_results.store vote.name, 0
        end
        vote_results[vote.name] += 1
      end
      max_votes = vote_results.values.max
      hit_list = Array.new

      vote_results.each do |key, value|
        if value == max_votes then
          hit_list << key
        end
      end
      
      if hit_list.length == 1 then
        victim = owner.player( hit_list.first )
        victim.die
        owner.chats['spirit'].add_player victim
        killed = victim.name
        owner.message "#{killed}が吊られました。"
        return :proceed
      elsif hit_list.length == 0 then
        owner.message "投票は一つもなかったようです..."
        owner.inactivity_strike
        return :proceed
      else
        return hit_list
      end
    end

    #Abstract as "retry phase"
    def revote(revote_players, trys)
      owner.inactivity_strike
      owner.message '同じ票数の人がいたので決選投票を行います。'
      owner.message "#{trys}回以内に処刑する人を決めてください。"
      @action_queue = Array.new
      @action_confirmed = Array.new
      phase_timer
    end

    def get_player_list(player)
      return :player_list_with_selections
    end

    def current_action_name_of_player(player)
      player.role.day_action_name
    end

  end
end
