module Role
  class Werewolf < GenericRole

    def execute_action(player)
      player.die
    end
  end
end
