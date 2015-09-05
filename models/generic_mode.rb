require 'observer'

module Mode
  class GenericMode

    include Observable

    attr_accessor :owner

  end
end
