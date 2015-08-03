module Role
  class Werewolf < GenericRole

    attr_reader :realtime_hitlist

    def initialize
      @name = "Werewolf"
      @realtime_hitlist = Hash.new
      @action_queue = Hash.new
      super
    end

    def player_list_f
      'quadstate'
    end

    def night_action_direct?
      false
    end

    def indirect_confirm_string
      '殺害対象に関する意見を受け付けました'
    end

    def execute_actions
      score_hash = Hash.new
      max = 0
      kill_queue = Array.new
      @realtime_hitlist.each do |target, hash|
        score_hash.store target, 0
        hash.each do |player, score|
          score_hash[target] += score
        end
        if score_hash[target] >= max then
          max = score_hash[target]
          kill_queue << owner.player( target )
        end
      end
      kill_queue.shuffle!
      kill_queue.first.die
    end

    def night_action_name
      "Kill Player"
    end

    def divine
      "Werewolf side"
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
