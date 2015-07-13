class Round
  @players

  def initialize
    @players = Array.new
  end

  def add_player(name)
    @players << Player.new(:name => name)
    @players.last.name
  end

end
