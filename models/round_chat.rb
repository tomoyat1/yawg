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
      formatted_msg = "<div>#{player.name} &gt; #{msg}</div>"
      return { players: @players, msg: formatted_msg }
    else
      return nil
    end
  end
end
