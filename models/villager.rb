module Role
  class Villager < GenericRole

    def initialize
      super
      @name = "村人"
      @night_action_name = "怯える"
      @night_action_auto = true
      @night_action_direct = true
    end

    def execute_actions
      return 'あなたは怯えています。'
    end

  end
end
