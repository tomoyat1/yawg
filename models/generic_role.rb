module Role
  class GenericRole

    @@desendants = Array.new

    def self.inherited(child)
      @@desendants << child.shown_name
    end

    def self.desendants
      @@desendants
    end

    def self.shown_name
      self.name.split('::').last || ''
    end

    def self.day_action_name
      "Vote to kill player"
    end

    def self.night_action_name
      nil
    end
  end
end
