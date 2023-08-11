# frozen_string_literal: true

# Problem:
# This is known as the Mars Rover problem. Implement something that matches this description

# Have some kind of NxN grid (where N > 10). Each cell in this grid can either be:
# a) the mars rover itself
# b) passable terrain
# c) impassable terrain (imagine it is a rock or something)

# The board will start with the rover randomly placed, and some amount of impassable terrain added.

# The rover can receive 5 possible commands
# a) move forward
# b) move backwards
# c) rotate to the left
# d) rotate to the right
# e) shutdown (quit the game)
# The rover can move into any passable terrain, but not the impassable ones.

# The grid also wraps. If the Rover goes too far off to the right, they should appear on the left
#  (and same goes for up and down too)

# The grid should be displayed to the user so they can understand which way the rover is facing and where they can move.

# class for Game logic
class Game
  SIZE_BOARD = 15
  VALID_MOVES = %w[W A S D X].freeze
  METHODS_BY_MOVES = {
    'W' => 'move_forward',
    'S' => 'move_backwards',
    'A' => 'rotate_left',
    'D' => 'rotate_right'
  }.freeze

  def initialize
    @board = Board.new(SIZE_BOARD)
    @rover = Rover.new(@board)
  end

  def play
    loop do
      display_data
      @input_user = retrieve_rover_movement
      next display_error unless data_is_valid?
      break if @input_user == VALID_MOVES[4]

      process_user_input
    end
  end

  def finish_validation
    data_is_valid? || must_continue?
  end

  def data_is_valid?
    return false if @input_user.nil?
    return false unless VALID_MOVES.include?(@input_user)

    true
  end

  def must_continue?
    valid_moves = VALID_MOVES - [VALID_MOVES[4]]
    valid_moves.include?(@input_user)
  end

  def display_data
    @rover.display_coordinates
    @board.display(@rover, @last_x, @last_y)
  end

  def process_user_input
    @last_x = @rover.x
    @last_y = @rover.y
    @rover.send(METHODS_BY_MOVES[@input_user])
  end

  def retrieve_rover_movement
    puts
    display_instructions
    gets.strip.upcase
  end

  def display_instructions
    puts '---------------------WELCOME TO ROVER MARS--------------------------------------'
    puts ' if you want to rover go forward press W,'
    puts ' if you want to rover go backwards press S,'
    puts  'if you want to rotate the Rover to the right press D '
    puts  'if you want to rotate the Rover to the left press A '
    puts 'press X to quit the game'
  end

  def display_error
    puts 'Invalid move. Try again.'
  end
end

# class for Board game and terrain
class Board
  attr_accessor :terrain

  PASSABLE_TERRAIN_CHAR = '-'
  IMPASSABLE_TERRAIN_CHAR = '#'
  VALID_MOVES = %w[W A S D].freeze
  CHAR_FACTOR = 4

  def initialize(size)
    @combined_chars = PASSABLE_TERRAIN_CHAR * CHAR_FACTOR + IMPASSABLE_TERRAIN_CHAR
    @terrain = Array.new(size) { Array.new(size) { generate_random_char } }
    @range_state = 0...@terrain.first.length
  end

  def generate_random_char
    @combined_chars[rand(@combined_chars.length)]
  end

  def display(rover, last_x, last_y)
    locate_rover(rover.x, rover.y)
    replace_last_cell(last_x, last_y) unless last_x == rover.x && last_y == rover.y
    print_board(rover.x, rover.y)
  end

  def print_board(_rover_x, _rover_y)
    puts '      ' + @range_state.map { |i| formatted_number(i) }.join('  ')
    @terrain.each_with_index do |row, x|
      print "#{formatted_number(x)}-> | "
      row.each { |element| print "#{element} | " }
      puts
    end
  end

  def locate_rover(rover_x, rover_y)
    @terrain[rover_x][rover_y] = Rover::SYMBOL
  end

  def replace_last_cell(actual_x, actual_y)
    @terrain[actual_x.to_i][actual_y.to_i] = PASSABLE_TERRAIN_CHAR
  end

  def formatted_number(number)
    number < 10 ? " #{number}" : number
  end

  def impassable?(x, y)
    @terrain[x][y] == IMPASSABLE_TERRAIN_CHAR
  end
end

# Class for Rover logic
class Rover
  attr_accessor :x, :y, :symbol, :direction

  SYMBOL = 'R'
  CONVERSIONS_ON_LEFT_ROTATION = {
    'N' => 'W',
    'S' => 'E',
    'W' => 'S',
    'E' => 'N'
  }.freeze
  CONVERSIONS_ON_RIGHT_ROTATION = {
    'N' => 'E',
    'S' => 'W',
    'W' => 'N',
    'E' => 'S'
  }.freeze

  def initialize(board)
    @board = board
    @direction = 'N'
    @symbol = SYMBOL
    @x = rand(@board.terrain.first.size)
    @y = rand(@board.terrain.first.size)
  end

  def move_forward
    move(next_forward_position)
  end

  def move_backwards
    move(next_backward_position)
  end

  def move(next_coordinates)
    @new_x, @new_y = next_coordinates
    @board.impassable?(@new_x, @new_y) ? error_terrain : set_new_coordinates
  end

  def set_new_coordinates
    @x = @new_x
    @y = @new_y
  end

  def rotate_left
    change_direction_with_left_rotation
  end

  def rotate_right
    change_direction_with_right_rotation
  end

  def display_coordinates
    puts "Rover is at coordinates #{@x}, #{@y} looking to -> #{@direction}"
  end

  def error_terrain
    puts ' <> DANGER <> -> Terrain impassable, please try again <- <> DANGER <>'
  end

  def change_direction_with_left_rotation
    @direction = CONVERSIONS_ON_LEFT_ROTATION[@direction]
  end

  def change_direction_with_right_rotation
    @direction = CONVERSIONS_ON_RIGHT_ROTATION[@direction]
  end

  def next_forward_position
    case @direction
    when 'S' then [check_limit(@x + 1), @y]
    when 'N' then [check_limit(@x - 1), @y]
    when 'E' then [@x, check_limit(@y + 1)]
    when 'W' then [@x, check_limit(@y - 1)]
    end
  end

  def next_backward_position
    case @direction
    when 'N' then [check_limit(@x + 1), @y]
    when 'S' then [check_limit(@x - 1), @y]
    when 'W' then [@x, check_limit(@y + 1)]
    when 'E' then [@x, check_limit(@y - 1)]
    end
  end

  def check_limit(position)
    return 0 if position > (@board.terrain.length - 1)
    return (@board.terrain.length - 1) if position.negative?

    position
  end
end

game = Game.new
game.play
