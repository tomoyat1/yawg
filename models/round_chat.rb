class RoundChat

  attr_accessor :owner

  def initialize(name)
    @name = name
    @players = Hash.new
  end

  def add_player(player)
    unless @players.value?( player ) then
      @players.store player.name, player
    end
  end

  def send_msg(player:, msg:)
    formatted_msg = ''
    if @players.value?( player ) && msg != '' then
      return { players: @players, speaker: player, msg: msg }
    else
      return nil
    end
  end
end
