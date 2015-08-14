module Role
  class Werewolf < GenericRole

    attr_reader :realtime_hitlist

    def initialize
      super
      @name = "人狼"
      @realtime_hitlist = Hash.new
      @action_queue = Array.new
      @night_action_name = "殺害候補を確定する"
      @player_list_f = :player_list_with_selections_quadstate
      @divine_result = "人狼"
      @is_count_evil = true
      @is_side_evil = true
    end

    def indirect_confirm_string
      '殺害対象に関する意見を受け付けました'
    end

    def execute_actions
      score_hash = Hash.new
      kill_queue = Array.new
      @realtime_hitlist.each do |target, hash|
        score_hash.store target, 0
        hash.each do |player, score|
          score_hash[target] += score
        end
        max = score_hash.values.max
        if score_hash[target] == max then
          kill_queue << owner.player( target )
        end
      end
      unless kill_queue.empty? then
        kill_queue.shuffle!
        kill_queue.last.die
        killed_name = kill_queue.last.name
        owner.message "#{killed_name}は殺されました。"
      else
        owner.message "人狼達は誰を殺すか合意できなかったようです..."
      end
    end

    def update_hitlist(player_name:, target_name:, score:)
      unless @realtime_hitlist.key?(target_name) then
        @realtime_hitlist.store(target_name, Hash.new)
      end
      unless @realtime_hitlist[target_name].key?(player_name) then
        @realtime_hitlist[target_name].store('total', 0)
        @realtime_hitlist[target_name].store(player_name, score)
      else
        @realtime_hitlist[target_name][player_name] = score
      end
      target_total = 0
      @realtime_hitlist[target_name].each do |key, value|
        unless key == 'total' then
          target_total += value
        end
      end
      @realtime_hitlist[target_name]['total'] = target_total
      return target_name
    end

    def reset_state
      @realtime_hitlist = Hash.new
    end
  end
end
