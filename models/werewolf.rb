module Role
  class Werewolf < GenericRole

    def execute_action(player)
      player.die
    end

    def self.night_action_name
      "Kill Player"
    end
  end
end
