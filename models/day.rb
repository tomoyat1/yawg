require_relative 'generic_phase'

module Phase
  class Day < GenericPhase

    def initialize(index)
      super
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
        owner.player( hit_list.first ).die
        killed = hit_list.first
        owner.message "#{killed}が吊られました。"
      else
        hit_list.each do |target|
          owner.player( target ).die
          owner.message "#{target}は吊られました"
        end
        owner.message '複数人が吊られました'
      end
    end

    def get_player_list(player)
      return :player_list_with_selections
    end

    def current_action_name_of_player(player)
      player.role.day_action_name
    end
  end
end
