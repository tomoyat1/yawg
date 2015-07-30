class Player

  attr_reader :name
  attr_accessor :role
  attr_accessor :info_list

  def initialize(args)
    @name = args[:name]
    @info_list = Array.new
  end

  def 

  def die
    @is_alive = false
  end
end
