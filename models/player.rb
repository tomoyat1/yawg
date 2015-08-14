class Player

  attr_reader :name
  attr_reader :role
  attr_reader :is_alive
  attr_reader :player_list_f

  def initialize(args)
    @name = args[:name]
    @is_alive = true
  end

  def die
    @is_alive = false
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
