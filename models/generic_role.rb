module Role
  class GenericRole
    @@desendants = Array.new
    def self.inherited(child)
      @@desendants << child.role_name
    end

    def self.desendants
      @@desendants
    end

    def self.role_name
      self.name.split('::').last || ''
    end
  end
end
