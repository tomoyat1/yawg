require_relative 'generic_phase'

module Phase
  class Day < GenericPhase

    def execute_actions
      @action_hash.each do |key, value|
        @vote_results[value]+= 1
      end
      max_votes = @vote_results.values.max
      hit_list = Array.new
      @vote_results.each do |key, value|
        if value = max_votes then
          hit_list << key
        end
      end
      if hit_list.length == 1 then
        key.kill
      else
        #TODO: Do something about tie situations.
        puts 'I DON\'T KNOW WHAT TO DO!!!'
        hit_list.each do |player|
          player.kill
        end
      end
    end

    def current_action_name_of_player(player)
      player.role.day_action_name
    end
  end
end
