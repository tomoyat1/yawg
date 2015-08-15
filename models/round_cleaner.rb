require 'singleton'

class RoundCleaner
  include Singleton

  def initialize
    Thread.abort_on_exception = true
    @time_left = Hash.new
    @watcher = Thread.start do
      loop do
        sleep 60
        @time_left.each_key do |round_name| 
          @time_left[round_name] -= 1
          if @time_left[round_name] <= 0 then
            release round_name
            disable_monitoring round_name
          elsif @time_left[round_name] == 1 then
            Yawg.send_msg_to_round round_name, "1分以内に開始しないとゲームは削除されます。"
          end
        end
      end
    end
  end

  def release(round_name)
    puts "Released round #{round_name}"
    Yawg.delete_round round_name
  end

  def monitor_round_in_staging(round_name)
    @time_left.store round_name, 5
  end

  def disable_monitoring(round_name)
    @time_left.delete round_name
  end
end
