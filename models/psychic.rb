module Role
  class Psychic < GenericRole

    def initialize
      super
      @name = '霊媒師'
      @night_action_name = '死者の声を聞く'
      @night_action_auto = true
      @night_action_direct = true
    end
      
    def execute_actions
      puts "Psychic action"
      if owner.last_killed then
        if owner.last_killed.role.class == Werewolf then
          return "処刑された#{owner.last_killed.name}は人狼でした。"
        else
          return "処刑#{owner.last_killed.name}は人狼ではありませんでした。"
        end
      else
        return "声を聞く人がいません。"
      end
    end
  end
end
