module Phase
  class GenericPhase

    attr_reader :action_queue
    attr_reader :index
    attr_reader :shown_name
    attr_accessor :owner

    def initialize(index)
      @index = index
      @action_queue = Array.new
      @action_confirmed = Array.new
      @clock = 3
    end

    def start_phase
      owner.message @start_msg
      phase_timer
    end

    def phase_timer
      owner.message "残り#{@clock}分です。"
      if @tick then
        @tick.cancel
      end
      @tick = EM.add_periodic_timer(60) do
        @clock -= 1
        unless @clock <= 0 then
          owner.message "残り#{@clock}分です。"
        else
          owner.message @timeup_msg
          owner.next_phase
          @tick.cancel
        end
      end
    end

    def extend_phase(minutes)
      @clock += minutes
      owner.message "時間を#{minutes}分延長しました"
    end

    def skip_remaining_time
      owner.message @timeup_msg
      owner.next_phase
      @tick.cancel
    end

    def end_phase
      execute_non_imediate_actions
    end

    def get_player_list(player)
      player.role.player_list_f
    end

    def class_name
      self.class.name.split('::').last || ''
    end

    def add_action(player:, target:)
      #stub
    end

    def execute_non_imediate_actions
      @action_queue.each do |hash|
        hash[:player].role.stage_action target: hash[:target]
      end
    end

    def current_action_name_of_player(player)
      player.role.day_action_name
    end

    def realtime_action_handler(player:, data:)
      #stub
    end

    def release_owner
      @owner = nil
    end

    def kill_tick
      if @tick.respond_to?( :cancel ) then
        @tick.cancel
      end
    end

  end
end
