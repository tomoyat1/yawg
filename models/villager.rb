require 'singleton'

module Role
  class Villager < GenericRole

    include Singleton
    
    def initialize
      @name = "Villager"
      super
    end

  end
end
