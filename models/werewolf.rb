require 'singleton'

module Role
  class Werewolf < GenericRole

    include Singleton

    attr_reader :realtime_hitlist

    def initialize
      @name = "Werewolf"
      @realtime_hitlist = Hash.new
      super
    end

    def execute_night_action(hitlist)
      hitlist.last.die
    end

    def night_action_name
      "Kill Player"
    end

    def add_night_action_by_player(player:, action:)
      unless @night_action_queue.key?(player) then
        @night_action_queue.store(player, nil)
      end
      @night_action_queue[player] = action
    end

    def update_hitlist(player_name:, target:, score:)
      unless @realtime_hitlist.key?(target) then
        @realtime_hitlist.store(target, Hash.new)
      end
      unless @realtime_hitlist[target].key?(player_name) then
        @realtime_hitlist[target].store('total', 0)
        @realtime_hitlist[target].store(player_name, score)
      else
        @realtime_hitlist[target][player_name] = score
      end
      target_total = 0
      @realtime_hitlist[target].each do |key, value|
        unless key == 'total' then
          target_total += value
        end
      end
      @realtime_hitlist[target]['total'] = target_total
      return target
    end

    def reset_state
      @realtime_hitlist = Hash.new
    end
  end
end
