require 'tilt'

class WSController

  @@sockets = Hash.new
  @@next_msg = nil
  
  def self.sockets
    @@sockets
  end

  def self.add_to_next_msg(key:, value:)
    unless @@next_msg then
      @@next_msg = Hash.new
    end
    @@next_msg.store(key, value)
  end

  def self.send_msg_to_player_in_game(msg: @@next_msg, player:, game:)
    if @@sockets[game].key?(player) then
      @@sockets[game][player].send(msg.to_json)
    end
    if msg == @@next_msg then
      @@next_msg = Hash.new
    end
  end

  def self.queue_erb(file_key, msg_key:, locals: {})
    file_path = "views/#{file_key.id2name}.erb"
    template = Tilt.new(file_path)
    rendered_string = template.render(self, locals)
    add_to_next_msg(key: msg_key, value: rendered_string)
  end

end
