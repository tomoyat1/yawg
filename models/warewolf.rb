class Warewolf < GenericRole
  def vote(player)

  end

  def action(player)
    player.kill
  end
end
