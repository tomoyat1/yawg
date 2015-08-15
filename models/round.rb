require 'observer'

require_relative 'generic_role'
require_relative 'villager'
require_relative 'werewolf'
require_relative 'generic_phase'
require_relative 'day'
require_relative 'night'

require_relative '../ws_controller'

include Role
include Phase

class Round

  include Observable

  attr_accessor :players
  attr_reader :name
  attr_reader :phases
  attr_reader :roles
  attr_reader :in_progress

  def initialize(name:)
    @in_progress = false
    @name = name
    @players = Hash.new
    @phases = Array.new
    @roles = Hash.new
    @round_survey = Hash.new
    @inactivity_strikes = 0

    GenericRole.desendants.each{|desendant| add_role(desendant.new) }
  end

  def add_player(name)
    unless @players.key?(name) then
      @players.store(name, Player.new(name: name))
      changed
      notify_observers players: @players, round: self, players_changed: true
      return true
    else
      return false
    end
  end

  def player(name)
    @players[name]
  end

  def current_phase
    @phases.last
  end

  def add_phase(phase)
    phase.owner = self
    @phases << phase
    @round_survey.store :good, 0
    @round_survey.store :evil, 0
  end

  def add_role(role)
    role.owner = self
    @roles.store(role.class.class_name, role)
  end

  def init_round(role_hash)
    unless @in_progress then
      @in_progress = true
      add_phase Night.new(1)

      role_array = Array.new
      role_hash.each do |key, value|
        value.times do
          role_array << key
        end
      end
      if role_array.size < @players.size then
        until role_array.size == @players.size
          role_array << "Villager" 
        end
      end
      role_array.shuffle!
      @players.values.each_index do |i|
        @players.values[i].role = @roles[role_array[i]]
      end
      
      changed
      notify_observers players: @players, round: self, round_start: true
      current_phase.start_phase
    else
      message "すでにゲームは開始されています。"
    end
  end

  def next_phase
    if @players.empty? then
      puts "Killing round #{@name} due to inactivity"
      release_round force: true
    else
      current_phase.end_phase
      unless @inactivity_strikes >= 3 then
        execute_survey
        if @round_survey[:good] > @round_survey[:evil] && @round_survey[:evil] != 0 then
          @roles['Werewolf'].reset_state
          #@roles['Knight'].reset_state
          if current_phase.class == Night then
            add_phase Day.new( current_phase.index )
          else
            add_phase Night.new( current_phase.index + 1 )
          end

          current_phase.start_phase
          alive = @players.select {|key, value| value.is_alive }
          changed
          notify_observers players: alive, round: self, next_phase: true

          dead = @players.select {|key, value| !value.is_alive }
          changed
          notify_observers players: dead, round: self, spirit_world: true

          @round_survey.each_value do |value|
            value = 0
          end
        else
          end_round
        end
      else
        message "入力が一定時間以上なかったのでゲームを終了します。ブラウザを閉じてください。"
        puts "Killing round #{@name} due to inactivity"
        release_round force: true
      end
    end
  end
  
  def execute_survey
    players.each_value do |player|
      if player.is_alive then
        if player.role.is_count_evil then
          @round_survey[:evil] += 1
        else
          @round_survey[:good] += 1
        end
      end
    end
  end

  def end_round
    winner_msg = ''
    winners = Hash.new
    losers = Hash.new
    if @round_survey[:evil] == 0 then
      winner_msg = '村人側の勝利です'
      winners = @players.reject {|key, value| value.role.is_side_evil }
      losers = @players.reject {|key, value| !value.role.is_side_evil }
    elsif @round_survey[:evil] >= @round_survey[:good] then
      winner_msg = '人狼側の勝利です'
      winners = @players.reject {|key, value| !value.role.is_side_evil }
      losers = @players.reject {|key, value| value.role.is_side_evil }
    end

    changed
    notify_observers players: @players,
                     round: self,
                     round_over: true,
                     winner_msg: winner_msg,
                     winners: winners,
                     losers: losers
    release_round
  end

  def action_name_of_player(player)
    current_phase.current_action_name_of_player( player )
  end

  def add_action_to_phase_queue(player_name:, target_names:)
    result = Hash.new
    targets = Array.new
    target_names.each do |target_name|
      targets << player( target_name )
    end
    result = current_phase.add_action player: player( player_name ),
                                      targets: targets 
    changed
    notify_observers players: @players, round: self, add_action: true, result: result
  end

  def realtime_handler(player_name:, data:)
      target = current_phase.realtime_action_handler( player: player( player_name ),
                                                      data: data )
      changed
      notify_observers players: @players,
                       round: self,
                       werewolf_realtime: true,
                       changed: target
  end

  def message(msg)
    changed
    notify_observers players: @players,
                     round: self,
                     timer_message: true,
                     msg: msg
  end

  def release_round **args
    current_phase.kill_tick
    @roles.each_value do |role|
      role.release_owner
    end
    @roles = nil

    @players.each_value do |player|
      if player then
        player.release_role
      end
    end
    #Players will be released upon disconnection

    @phases.each do |phase|
      phase.release_owner
    end
    @phases = nil

    if args[:force] then
      changed
      notify_observers players: @players, round: self, round_kill: true
    end
  end

  def inactivity_strike
    @inactivity_strikes += 1
  end
end
