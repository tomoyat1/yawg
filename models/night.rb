require_relative 'generic_phase'

module Phase
  class Night < GenericPhase

    attr_reader :action_hash

    def execute_actions
      @action_hash.each do |key, value|
         key.execute_action(value)
      end
    end
  end
end
