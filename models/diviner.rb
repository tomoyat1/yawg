module Role
  class Diviner < GenericRole

    def initialize
      super
      @name = "Diviner"
      @night_action_name = '占う'
      @player_list_f = :player_list_with_selections
      @night_action_direct = true
    end

    def execute_actions
      if @action_queue.last then
        divine = @action_queue.last.divine
        name = @action_queue.last.name
        super
        msg = "#{name}を占った結果#{divine}でした。"
      else
        msg = '占う相手を選択してください。'
      end
    end
  end
end
