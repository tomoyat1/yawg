module Role
  class Werewolf < GenericRole
    def vote(player)

    end

    def action(player)
      player.kill
    end

    def to_s
      'Werewolf'
    end
  end
end
