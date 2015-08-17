module Role
  class Madman < GenericRole
    
    def initialize
      super
      @name = "狂人"
      @is_side_evil = true
    end
  end
end
