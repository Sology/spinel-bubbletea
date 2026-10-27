# A bubbletea program driven by keys: the gem README's counter, plus a window-size
# readout. Needs a terminal; prints what it saw on exit.
require "bubbletea"

class Counter
  include Bubbletea::Model

  attr_reader :count, :seen, :size

  def initialize
    @count = 0
    @seen = []
    @size = nil
  end

  def init = [self, nil]

  def update(message)
    case message
    when Bubbletea::WindowSizeMessage
      @size = [message.width, message.height]
      [self, nil]
    when Bubbletea::KeyMessage
      @seen << message.to_s
      case message.to_s
      when "q", "ctrl+c" then [self, Bubbletea.quit]
      when "up", "k" then @count += 1; [self, nil]
      when "down", "j" then @count -= 1; [self, nil]
      else [self, nil]
      end
    else
      [self, nil]
    end
  end

  def view = "Count: #{@count}\n\nPress up/down to change, q to quit"
end

model = Counter.new
Bubbletea.run(model)
puts "count=#{model.count} seen=#{model.seen.inspect} size=#{model.size.inspect}"
