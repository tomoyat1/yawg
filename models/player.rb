require_relative 'generic_role'
class Player
  @name
  @role
  @is_alive

  attr_reader :name

  def initialize(args)
    args.each do |key, value|
      if key == :name then
        @name = value
      end
    end
  end

  def set_role(role)
    @role = role.new
  end

  def die
    @is_alive = false
  end
end
