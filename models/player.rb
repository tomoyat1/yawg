class Player

  attr_reader :name
  attr_accessor :role

  def initialize(args)
    args.each do |key, value|
      if key == :name then
        @name = value
      end
    end
  end

  def die
    @is_alive = false
  end
end
