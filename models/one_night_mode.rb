require_relative 'generic_mode'

module Mode
  class OneNightMode < GenericMode

    def initialize
      @survey = Hash.new
      reset_survey
    end

    def next_phase
      execute_survey
      if @survey[:good] == 0 then
        round_result false
      elsif @survey[:evil] == 0 then
        round_result true
      elsif owner.current_phase.class == Night then
        progress_game
      elsif owner.current_phase.class == Day then
        end_round
      end
    end

    def execute_survey
      owner.players.each_value do |player|
        if player.is_alive then
          if player.role.is_count_evil then
            @survey[:evil] += 1
          else
            @survey[:good] += 1
          end
        end
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
    end

    def end_round
      winner_msg = ''
      winners = Hash.new
      losers = Hash.new
      if owner.last_killed then
        if owner.last_killed.role.class == Werewolf then
          round_result true
        else
          round_result false
        end
      else
        if @survey[:good] > @survey[:evil] then
          round_result true
        else
          round_result false
        end
      end

    end


    def reset_survey
      @survey.store :good, 0
      @survey.store :evil, 0
    end

  end
end
