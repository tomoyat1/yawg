class Player

  attr_reader :name
  attr_reader :role
  attr_reader :is_alive
  attr_reader :is_protected
  attr_accessor :is_host
  attr_reader :is_spirit_world_sent

  def initialize(args)
    @name = args[:name]
    @is_alive = true
    @is_protected = false
    @is_host = false
    @is_spirit_world_sent = false
  end

  def die
    unless @is_protected then
      @is_alive = false
      return true
    else
      @is_protected = false
      return false
    end
  end

  def protect
    @is_protected = true
  end

  def unprotect
    @is_protected = false
  end

  def spirit_world_sent
    @is_spirit_world_sent = true
  end

  def role=(role)
    @role = role
    role.add_player(self)
  end

  def add_night_action(action)
    @role.add_night_action_by_player player: self.name, action: action
  end

  def divine
    @role.divine
  end

  def release_role
    @role = nil
  end
end
