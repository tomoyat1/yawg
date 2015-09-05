require 'observer'

module Mode
  class GenericMode

    include Observable

    attr_accessor :owner

    def round_result(good_wins)
      if good_wins then
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
