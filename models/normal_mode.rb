require_relative 'generic_mode'

module Mode
  class NormalMode < GenericMode

    def initialize
      @survey = Hash.new
      reset_survey
    end

    def next_phase
      execute_survey
      if @survey[:good] > @survey[:evil] && @survey[:evil] != 0 then
        progress_game
      else
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
      owner.roles.each_value do |role|
        role.reset_state
      end
      if owner.current_phase.class == Night then
        owner.add_phase Day.new( owner.current_phase.index )
      else
        owner.add_phase Night.new( owner.current_phase.index + 1 )
      end

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
      reset_survey
    end

    def end_round
      winner_msg = ''
      winners = Hash.new
      losers = Hash.new
      if @survey[:evil] == 0 then
        round_result true
      elsif @survey[:evil] >= @survey[:good] then
        round_result false
      end
    end

    def reset_survey
      @survey.store :good, 0
      @survey.store :evil, 0
    end

  end
end
