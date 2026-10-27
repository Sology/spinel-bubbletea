# The gem's messages, commands and model without a terminal: key names from the
# Go side, input events parsed by the Go parser into messages, the command
# constructors, and the string width the renderer measures with.
require "bubbletea"

p Bubbletea::VERSION
p Bubbletea.version
p [Bubbletea.get_key_name(-2), Bubbletea.get_key_name(13), Bubbletea.get_key_name(3), Bubbletea.get_key_name(-25)]

events = [
  { "type" => "key", "key_type" => -1, "runes" => [106], "alt" => false, "name" => "j" },
  { "type" => "key", "key_type" => -2, "runes" => nil, "alt" => false, "name" => "up" },
  { "type" => "key", "key_type" => 13, "runes" => nil, "alt" => false },
  { "type" => "key", "key_type" => -1, "runes" => [228], "alt" => true },
  { "type" => "mouse", "x" => 3, "y" => 4, "button" => 4, "action" => 0 },
  { "type" => "focus" },
  { "type" => "blur" },
  { "type" => "other" },
]
events.each do |e|
  m = Bubbletea.parse_event(e)
  case m
  when Bubbletea::KeyMessage
    p [m.class, m.to_s, m.key_type, m.char, m.runes?, m.up?, m.enter?, m.ctrl?]
  when Bubbletea::MouseMessage
    p [m.class, m.x, m.y, m.wheel?, m.press?]
  else
    p m.class
  end
end
p Bubbletea.parse_event(nil)

w = Bubbletea::WindowSizeMessage.new(width: 120, height: 40)
p [w.width, w.height]

class Counter
  include Bubbletea::Model
end
c = Counter.new
p [c.init.size, c.update(w)[1], c.view]

p Bubbletea.quit.class
b = Bubbletea.batch(Bubbletea.quit, nil, [Bubbletea.enter_alt_screen])
p [b.class, b.commands.map(&:class)]
s = Bubbletea.sequence(Bubbletea.exit_alt_screen, Bubbletea.set_window_title("t"))
p [s.class, s.commands.map(&:class), s.commands.last.title]
t = Bubbletea.tick(0.5) { :tick }
p [t.class, t.duration, t.callback.call]
m = Bubbletea.send_message(w, delay: 2)
p [m.class, m.delay, m.message.width]
p [Bubbletea.none, Bubbletea.puts("x").text, Bubbletea.suspend.class, Bubbletea.exec(-> { 1 }).class]

prog = Bubbletea::Program.new
p [prog.string_width("hello"), prog.string_width("héllo"), prog.string_width("日本")]
