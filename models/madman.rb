module Role
  class Madman < GenericRole
    
    def initialize
      super
      @name = "狂人"
      @night_action_name = "普通の人のふりをする"
      @night_action_auto = true
      @night_action_direct = true
    end

    def execute_actions
      return 'あなたは普通の人のふりをしています。'
    end

  end
end
