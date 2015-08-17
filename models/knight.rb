module Role
  class Knight < GenericRole

    def initialize
      super
      @name = '騎士'
      @night_action_name = '守る'
      @player_list_f = :player_list_with_selections
      @night_action_direct = false
    end

    def indirect_confirm_string
      '守る相手を確定しました。複数の騎士が異なる人を選んでいる場合は、その中からランダムで守られる人が確定します。'
    end

    def execute_actions
      @action_queue.shuffle!
      if @action_queue.first then
        @action_queue.first.protect
      end
    end
  end
end
