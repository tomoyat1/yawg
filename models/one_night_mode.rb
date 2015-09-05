require_relative 'generic_mode'

module Mode
  class OneNightMode < GenericMode

    def next_phase
      if owner.current_phase.class == Night then
        progress_game
      elsif owner.current_phase.class == Day then
        end_round
      end
    end

    def progress_game
      owner.add_phase Day.new( owner.current_phase.index + 1 )
      owner.players.each_value do |player|
        player.unprotect
      end
      owner.current_phase.start_phase
      alive = owner.players.select {|key, value| value.is_alive }
      changed
      notify_observers players: alive, round: owner, next_phase: true

      dead = owner.players.select do |key, value|
        !value.is_alive && !value.is_spirit_world_sent
      end
      dead.each_value do |player|
        player.spirit_world_sent
      end
      changed
      notify_observers players: dead, round: owner, spirit_world: true
      puts "progressing game"
    end

    def end_round
      winner_msg = ''
      winners = Hash.new
      losers = Hash.new
      if owner.last_killed.role.class == Werewolf then
        winner_msg = '村人側の勝利です'
        winners = owner.players.reject {|key, value| value.role.is_side_evil }
        losers = owner.players.reject {|key, value| !value.role.is_side_evil }
      else
        winner_msg = '人狼側の勝利です'
        winners = owner.players.reject {|key, value| !value.role.is_side_evil }
        losers = owner.players.reject {|key, value| value.role.is_side_evil }
      end

      changed
      notify_observers players: owner.players,
                       round: owner,
                       round_over: true,
                       winner_msg: winner_msg,
                       winners: winners,
                       losers: losers
      owner.release_round
    end
  end
end
