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
          elsif @time_left[round_name] == 1 then
            Yawg.send_msg_to_round round_name, "あと1分でゲームは削除されます。"
          end
        end
      end
    end
  end

  def release(round_name)
    puts "Released round #{round_name}"
    disable_monitoring round_name
    Yawg.send_msg_to_round round_name, '<script>window.location = "/game"</script>'
    Yawg.delete_round round_name
  end

  def monitor_round(round_name)
    @time_left.store round_name, 1440
  end

  def disable_monitoring(round_name)
    @time_left.delete round_name
  end
end
