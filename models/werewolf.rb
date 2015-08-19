module Role
  class Werewolf < GenericRole

    attr_reader :realtime_hitlist

    def initialize
      super
      @name = "人狼"
      @realtime_hitlist = Hash.new
      @night_action_name = "殺害候補を確定する"
      @player_list_f = :player_list_with_selections_quadstate
      @divine_result = "人狼"
      @is_count_evil = true
      @is_side_evil = true
      @inactivity_strikes = 0
    end

    def role_msg
      role_msg = "あなたの役職は#{@name}です。"
      role_msg << "今回は次の人たちが人狼です: "
      @players.each do |player_name|
        role_msg << "#{player_name} "
      end
      role_msg
    end

    def indirect_confirm_string
      '殺害対象に関する意見を受け付けました'
    end

    def execute_actions
      score_hash = Hash.new
      kill_queue = Array.new

      @action_queue.each do |target|
        unless score_hash.key?( target.name ) then
          score_hash.store target.name, 0
        end
        score_hash[target.name] += 1
      end

      max = score_hash.values.max
      score_hash.each do |target_name, score|
        if score == max then
          kill_queue << owner.player( target_name )
        end
      end

      unless kill_queue.empty? then
        kill_queue.shuffle!
        if kill_queue.last.die then
          owner.chats['spirit'].add_player kill_queue.last
          killed_name = kill_queue.last.name
          owner.message "#{killed_name}は殺されました。"
        else
          owner.message '誰も殺されませんでした'
        end
      else
        owner.message "人狼達は誰を殺すか合意できなかったようです..."
        owner.inactivity_strike
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
      super
    end
  end
end
