# frozen_string_literal: true

# The bubbletea gem (marcoroth/bubbletea-ruby 0.1.4, MIT, see LICENSE.txt) for
# Spinel. The Ruby below is the gem's lib/bubbletea/*.rb, unchanged and in the
# gem's load order; its C extension (ext/bubbletea) is written in Ruby over the
# Go archive (go/, the gem's own Go code, built by spin.toml's [[build]] step) and
# sp_bubbletea.c. Departures are marked SIMPLIFIED.

# ---- lib/bubbletea/version.rb -----------------------------------------------------
module Bubbletea
  VERSION = "0.1.4"
end

# ---- ext/bubbletea (extension.c, program.c): the C extension, in Ruby -------------
# The Go archive's exports bind directly where they take and answer numbers or take
# strings; sp_bubbletea.c covers the ones answering a Go-allocated string or out-
# parameters. Handles are the Go side's integer ids (unsigned long long there).
require "json"

module Bubbletea
  module Native
    ffi_func :tea_new_program,                         [],                  :long
    ffi_func :tea_terminal_init,                       [:long],             :int
    ffi_func :tea_terminal_enter_raw_mode,             [:long],             :int
    ffi_func :tea_terminal_exit_raw_mode,              [:long],             :int
    ffi_func :tea_terminal_enter_alt_screen,           [:long],             :void
    ffi_func :tea_terminal_exit_alt_screen,            [:long],             :void
    ffi_func :tea_terminal_hide_cursor,                [:long],             :void
    ffi_func :tea_terminal_show_cursor,                [:long],             :void
    ffi_func :tea_terminal_enable_mouse_cell_motion,   [:long],             :void
    ffi_func :tea_terminal_enable_mouse_all_motion,    [:long],             :void
    ffi_func :tea_terminal_disable_mouse,              [:long],             :void
    ffi_func :tea_terminal_enable_bracketed_paste,     [:long],             :void
    ffi_func :tea_terminal_disable_bracketed_paste,    [:long],             :void
    ffi_func :tea_terminal_enable_report_focus,        [:long],             :void
    ffi_func :tea_terminal_disable_report_focus,       [:long],             :void
    ffi_func :tea_input_start_reader,                  [:long],             :int
    ffi_func :tea_input_stop_reader,                   [:long],             :void
    ffi_func :tea_renderer_new,                        [:long],             :long
    ffi_func :tea_renderer_render,                     [:long, :str],       :void
    ffi_func :tea_renderer_set_size,                   [:long, :int, :int], :void
    ffi_func :tea_renderer_set_alt_screen,             [:long, :int],       :void
    ffi_func :tea_renderer_clear,                      [:long],             :void
    ffi_func :tea_string_width,                        [:str],              :int
    ffi_func :tea_terminal_is_tty,                     [],                  :int
    ffi_func :tea_terminal_clear_screen,               [],                  :void
    ffi_func :tea_terminal_set_window_title,           [:str],              :void
    ffi_func :sp_tea_upstream_version,                 [],                  :str
    ffi_func :sp_tea_get_key_name,                     [:long],             :str
    ffi_func :sp_tea_terminal_size,                    [:long],             :long
    ffi_func :sp_tea_read_raw_input,                   [:long, :long],      :binstr
    ffi_func :sp_tea_poll_event,                       [:long, :long],      :str
  end

  # extension.c's module functions
  def self.upstream_version
    Native.sp_tea_upstream_version
  end

  def self.version
    format("bubbletea v%s (upstream charmbracelet/x/ansi %s) [Go native extension]", VERSION, upstream_version)
  end

  def self.tty?
    Native.tea_terminal_is_tty != 0
  end

  def self.clear_screen
    Native.tea_terminal_clear_screen
    nil
  end

  def self._set_window_title(title)
    Native.tea_terminal_set_window_title(title)
    nil
  end

  def self.get_key_name(key_type)
    Native.sp_tea_get_key_name(key_type)
  end

  # program.c's Bubbletea::Program. SIMPLIFIED: the extension frees the Go program
  # (tea_free_program) when the object is collected; a Program here lives until the
  # process ends, which is what a TUI's one program does anyway.
  class Program
    def initialize
      @handle = Native.tea_new_program
      Native.tea_terminal_init(@handle)
    end

    def enter_raw_mode = Native.tea_terminal_enter_raw_mode(@handle) == 0
    def exit_raw_mode = Native.tea_terminal_exit_raw_mode(@handle) == 0

    def enter_alt_screen
      Native.tea_terminal_enter_alt_screen(@handle)
      nil
    end

    def exit_alt_screen
      Native.tea_terminal_exit_alt_screen(@handle)
      nil
    end

    def hide_cursor
      Native.tea_terminal_hide_cursor(@handle)
      nil
    end

    def show_cursor
      Native.tea_terminal_show_cursor(@handle)
      nil
    end

    def enable_mouse_cell_motion
      Native.tea_terminal_enable_mouse_cell_motion(@handle)
      nil
    end

    def enable_mouse_all_motion
      Native.tea_terminal_enable_mouse_all_motion(@handle)
      nil
    end

    def disable_mouse
      Native.tea_terminal_disable_mouse(@handle)
      nil
    end

    def enable_bracketed_paste
      Native.tea_terminal_enable_bracketed_paste(@handle)
      nil
    end

    def disable_bracketed_paste
      Native.tea_terminal_disable_bracketed_paste(@handle)
      nil
    end

    def enable_report_focus
      Native.tea_terminal_enable_report_focus(@handle)
      nil
    end

    def disable_report_focus
      Native.tea_terminal_disable_report_focus(@handle)
      nil
    end

    # [width, height], or nil when the terminal cannot say
    def terminal_size
      packed = Native.sp_tea_terminal_size(@handle)
      return nil if packed < 0

      [packed >> 32, packed & 0xffffffff]
    end

    def start_input_reader = Native.tea_input_start_reader(@handle) == 0

    def stop_input_reader
      Native.tea_input_stop_reader(@handle)
      nil
    end

    # the bytes one read got, or nil on a timeout or an error
    def read_raw_input(timeout_ms)
      bytes = Native.sp_tea_read_raw_input(@handle, timeout_ms)
      bytes.empty? ? nil : bytes
    end

    # the next input event as the Go parser describes it (a Hash), or nil
    def poll_event(timeout_ms)
      json = Native.sp_tea_poll_event(@handle, timeout_ms)
      json.empty? ? nil : JSON.parse(json)
    end

    def create_renderer = Native.tea_renderer_new(@handle)

    def render(renderer_id, view)
      Native.tea_renderer_render(renderer_id, view)
      nil
    end

    def renderer_set_size(renderer_id, width, height)
      Native.tea_renderer_set_size(renderer_id, width, height)
      nil
    end

    def renderer_set_alt_screen(renderer_id, enabled)
      Native.tea_renderer_set_alt_screen(renderer_id, enabled ? 1 : 0)
      nil
    end

    def renderer_clear(renderer_id)
      Native.tea_renderer_clear(renderer_id)
      nil
    end

    def string_width(str) = Native.tea_string_width(str)
  end
end

# ---- lib/bubbletea/messages.rb ----------------------------------------------------
module Bubbletea
  class Message
  end

  class KeyMessage < Message
    KEY_NULL      = 0
    KEY_CTRL_A    = 1
    KEY_CTRL_B    = 2
    KEY_CTRL_C    = 3
    KEY_CTRL_D    = 4
    KEY_CTRL_E    = 5
    KEY_CTRL_F    = 6
    KEY_CTRL_G    = 7
    KEY_CTRL_H    = 8
    KEY_TAB       = 9
    KEY_CTRL_J    = 10
    KEY_CTRL_K    = 11
    KEY_CTRL_L    = 12
    KEY_ENTER     = 13
    KEY_CTRL_N    = 14
    KEY_CTRL_O    = 15
    KEY_CTRL_P    = 16
    KEY_CTRL_Q    = 17
    KEY_CTRL_R    = 18
    KEY_CTRL_S    = 19
    KEY_CTRL_T    = 20
    KEY_CTRL_U    = 21
    KEY_CTRL_V    = 22
    KEY_CTRL_W    = 23
    KEY_CTRL_X    = 24
    KEY_CTRL_Y    = 25
    KEY_CTRL_Z    = 26
    KEY_ESC       = 27
    KEY_BACKSPACE = 127

    KEY_RUNES     = -1
    KEY_UP        = -2
    KEY_DOWN      = -3
    KEY_RIGHT     = -4
    KEY_LEFT      = -5
    KEY_HOME      = -6
    KEY_END       = -7
    KEY_PGUP      = -8
    KEY_PGDOWN    = -9
    KEY_DELETE    = -10
    KEY_INSERT    = -11
    KEY_F1        = -12
    KEY_F2        = -13
    KEY_F3        = -14
    KEY_F4        = -15
    KEY_F5        = -16
    KEY_F6        = -17
    KEY_F7        = -18
    KEY_F8        = -19
    KEY_F9        = -20
    KEY_F10       = -21
    KEY_F11       = -22
    KEY_F12       = -23
    KEY_SHIFT_TAB = -24
    KEY_SPACE     = -25

    attr_reader :key_type, :runes, :alt, :name

    def initialize(key_type:, runes: [], alt: false, name: nil)
      super()

      @key_type = key_type
      @runes = runes.is_a?(Array) ? runes : []
      @alt = alt
      @name = name || lookup_key_name
    end

    private

    def lookup_key_name
      base_name = if @key_type == KEY_RUNES && char
                    char
                  else
                    go_name = Bubbletea.get_key_name(@key_type)
                    go_name.empty? ? "unknown" : go_name
                  end

      @alt ? "alt+#{base_name}" : base_name
    end

    public

    def to_s
      @name
    end

    def char
      @runes.pack("U*") if @runes.any?
    end

    def ctrl?
      @key_type.between?(0, 31)
    end

    def runes?
      @key_type == KEY_RUNES
    end

    def space?
      @key_type == KEY_SPACE
    end

    def enter?
      @key_type == KEY_ENTER
    end

    def backspace?
      @key_type == KEY_BACKSPACE
    end

    def tab?
      @key_type == KEY_TAB
    end

    def esc?
      @key_type == KEY_ESC
    end

    def up?
      @key_type == KEY_UP
    end

    def down?
      @key_type == KEY_DOWN
    end

    def left?
      @key_type == KEY_LEFT
    end

    def right?
      @key_type == KEY_RIGHT
    end
  end

  class MouseMessage < Message
    BUTTON_NONE       = 0
    BUTTON_LEFT       = 1
    BUTTON_MIDDLE     = 2
    BUTTON_RIGHT      = 3
    BUTTON_WHEEL_UP   = 4
    BUTTON_WHEEL_DOWN = 5

    ACTION_PRESS   = 0
    ACTION_RELEASE = 1
    ACTION_MOTION  = 2

    attr_reader :x, :y, :button, :action, :shift, :alt, :ctrl

    def initialize(x:, y:, button:, action:, shift: false, alt: false, ctrl: false)
      super()

      @x = x
      @y = y
      @button = button
      @action = action
      @shift = shift
      @alt = alt
      @ctrl = ctrl
    end

    def press?
      @action == ACTION_PRESS
    end

    def release?
      @action == ACTION_RELEASE
    end

    def motion?
      @action == ACTION_MOTION
    end

    def wheel?
      @button >= BUTTON_WHEEL_UP
    end

    def left?
      @button == BUTTON_LEFT
    end

    def right?
      @button == BUTTON_RIGHT
    end

    def middle?
      @button == BUTTON_MIDDLE
    end
  end

  class WindowSizeMessage < Message
    attr_reader :width, :height

    def initialize(width:, height:)
      super()

      @width = width
      @height = height
    end
  end

  class FocusMessage < Message
  end

  class BlurMessage < Message
  end

  class QuitMessage < Message
  end

  class ResumeMessage < Message
  end

  def self.parse_event(hash)
    return nil if hash.nil?

    case hash["type"]
    when "key"
      KeyMessage.new(
        key_type: hash["key_type"],
        runes: hash["runes"] || [],
        alt: hash["alt"] || false,
        name: hash["name"]
      )
    when "mouse"
      MouseMessage.new(
        x: hash["x"],
        y: hash["y"],
        button: hash["button"],
        action: hash["action"],
        shift: hash["shift"] || false,
        alt: hash["alt"] || false,
        ctrl: hash["ctrl"] || false
      )
    when "focus"
      FocusMessage.new
    when "blur"
      BlurMessage.new
    end
  end
end

# ---- lib/bubbletea/commands.rb ----------------------------------------------------
module Bubbletea
  class Command
  end

  class QuitCommand < Command
  end

  class BatchCommand < Command
    attr_reader :commands

    def initialize(commands)
      super()

      @commands = commands
    end
  end

  class TickCommand < Command
    attr_reader :duration, :callback

    def initialize(duration, &callback)
      super()

      @duration = duration
      @callback = callback
    end
  end

  class SendMessage < Command
    attr_reader :message, :delay

    def initialize(message, delay: 0)
      super()

      @message = message
      @delay = delay
    end
  end

  class SequenceCommand < Command
    attr_reader :commands

    def initialize(commands)
      super()

      @commands = commands
    end
  end

  class EnterAltScreenCommand < Command
  end

  class ExitAltScreenCommand < Command
  end

  class SetWindowTitleCommand < Command
    attr_reader :title

    def initialize(title)
      super()

      @title = title
    end
  end

  class PutsCommand < Command
    attr_reader :text

    def initialize(text)
      super()

      @text = text
    end
  end

  class SuspendCommand < Command
  end

  class ExecCommand < Command
    attr_reader :callable, :message

    def initialize(callable, message: nil)
      super()
      @callable = callable
      @message = message
    end
  end

  class << self
    def quit
      QuitCommand.new
    end

    def batch(*commands)
      BatchCommand.new(commands.flatten.compact)
    end

    def tick(duration, &)
      TickCommand.new(duration, &)
    end

    def send_message(message, delay: 0)
      SendMessage.new(message, delay: delay)
    end

    def sequence(*commands)
      SequenceCommand.new(commands.flatten.compact)
    end

    def none
      nil
    end

    def enter_alt_screen
      EnterAltScreenCommand.new
    end

    def exit_alt_screen
      ExitAltScreenCommand.new
    end

    def set_window_title(title) # rubocop:disable Naming/AccessorMethodName
      SetWindowTitleCommand.new(title)
    end

    def puts(text)
      PutsCommand.new(text)
    end

    def suspend
      SuspendCommand.new
    end

    def exec(callable, message: nil)
      ExecCommand.new(callable, message: message)
    end
  end
end

# ---- lib/bubbletea/model.rb -------------------------------------------------------
module Bubbletea
  # Model module that provides the Elm Architecture interface.
  # Include this module in your model class and implement:
  #   - init: Returns [model, command] - initial state and optional command
  #   - update(message): Returns [model, command] - new state and optional command
  #   - view: Returns String - the current view to render
  #
  # Example:
  #   class Counter
  #     include Bubbletea::Model
  #
  #     attr_reader :count
  #
  #     def initialize
  #       @count = 0
  #     end
  #
  #     def init
  #       [self, nil]
  #     end
  #
  #     def update(message)
  #       case message
  #       when Bubbletea::KeyMessage
  #         case message.to_s
  #         when "q", "ctrl+c"
  #           [self, Bubbletea.quit]
  #         when "up", "k"
  #           @count += 1
  #           [self, nil]
  #         when "down", "j"
  #           @count -= 1
  #           [self, nil]
  #         else
  #           [self, nil]
  #         end
  #       else
  #         [self, nil]
  #       end
  #     end
  #
  #     def view
  #       "Count: #{@count}\n\nPress up/down to change, q to quit"
  #     end
  #   end
  #
  module Model
    def init
      [self, nil]
    end

    def update(_message)
      [self, nil]
    end

    def view
      ""
    end
  end
end

# ---- lib/bubbletea/runner.rb ------------------------------------------------------
module Bubbletea
  # Runner manages the event loop and coordinates between the model and the terminal
  class Runner
    attr_reader :options

    DEFAULT_OPTIONS = {
      alt_screen: false,
      mouse_cell_motion: false,
      mouse_all_motion: false,
      bracketed_paste: false,
      report_focus: false,
      fps: 60,
      input_timeout: 10,
      without_renderer: false,
    }.freeze

    def initialize(model, **options)
      @model = model
      @options = DEFAULT_OPTIONS.merge(options)
      @program = Program.new
      @renderer_id = nil
      @running = false
      @pending_ticks = []
      @width = 80
      @height = 24
      @resize_pending = false
      @previous_winch_handler = nil
      @in_alt_screen = false
    end

    def run
      setup_terminal
      @renderer_id = @program.create_renderer unless @options[:without_renderer]

      update_terminal_size
      @running = true

      new_model, command = @model.init
      @model = new_model if new_model
      process_command(command)

      return unless @running

      handle_message(WindowSizeMessage.new(width: @width, height: @height))

      render
      run_loop
      render
    ensure
      cleanup_terminal
    end

    def send(message)
      queue_message(message)
    end

    private

    # SIMPLIFIED: the gem calls its own send(result) for a message a command answers;
    # the port calls this, which send also calls. Spinel reads a call of send with a
    # computed argument as Kernel#send, a method named at run time, so every method of
    # the program would count as reachable from it.
    def queue_message(message)
      @pending_messages ||= []
      @pending_messages << message
    end

    def setup_terminal
      @program.enter_raw_mode
      @program.hide_cursor
      @program.start_input_reader

      if @options[:alt_screen]
        @program.enter_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, true) if @renderer_id
        @in_alt_screen = true
      end

      @program.enable_mouse_cell_motion if @options[:mouse_cell_motion]
      @program.enable_mouse_all_motion if @options[:mouse_all_motion]
      @program.enable_bracketed_paste if @options[:bracketed_paste]
      @program.enable_report_focus if @options[:report_focus]

      setup_resize_handler
    end

    def cleanup_terminal
      restore_resize_handler

      @program.disable_mouse if @options[:mouse_cell_motion] || @options[:mouse_all_motion]
      @program.disable_bracketed_paste if @options[:bracketed_paste]
      @program.disable_report_focus if @options[:report_focus]

      if @in_alt_screen
        @program.exit_alt_screen
      else
        print "\r\n"
      end

      @program.show_cursor
      @program.stop_input_reader
      @program.exit_raw_mode
    end

    def setup_resize_handler
      @previous_winch_handler = Signal.trap("WINCH") do
        @resize_pending = true
        @previous_winch_handler.call if @previous_winch_handler.is_a?(Proc)
      end
    rescue ArgumentError
      # SIGWINCH not supported on this platform
      @previous_winch_handler = nil
    end

    def restore_resize_handler
      if @previous_winch_handler
        Signal.trap("WINCH", @previous_winch_handler)
      else
        Signal.trap("WINCH", "DEFAULT")
      end
    rescue ArgumentError
      # SIGWINCH not supported on this platform
    end

    def update_terminal_size
      size = @program.terminal_size
      return unless size

      @width, @height = size
      @program.renderer_set_size(@renderer_id, @width, @height) if @renderer_id
    end

    def run_loop
      frame_duration = 1.0 / @options[:fps]
      last_frame = Time.now

      while @running
        check_resize
        process_pending_messages

        event = @program.poll_event(@options[:input_timeout])

        if event
          message = Bubbletea.parse_event(event)
          handle_message(message) if message
        end

        process_ticks

        now = Time.now

        if now - last_frame >= frame_duration
          render
          last_frame = now
        end
      end
    end

    def check_resize
      return unless @resize_pending

      @resize_pending = false

      size = @program.terminal_size
      return unless size

      new_width, new_height = size

      return if new_width == @width && new_height == @height

      @width = new_width
      @height = new_height

      @program.renderer_set_size(@renderer_id, @width, @height) if @renderer_id

      handle_message(WindowSizeMessage.new(width: @width, height: @height))
    end

    def process_pending_messages
      return unless @pending_messages&.any?

      messages = @pending_messages
      @pending_messages = []

      messages.each { |message| handle_message(message) }
    end

    def handle_message(message)
      return unless @running

      new_model, command = @model.update(message)
      @model = new_model if new_model
      process_command(command)
    end

    def process_command(command)
      return if command.nil?

      case command
      when QuitCommand
        @running = false

      when BatchCommand
        Thread.new do
          execute_batch_sync(command.commands)
        end

      when SequenceCommand
        Thread.new do
          execute_sequence_sync(command.commands)
        end

      when TickCommand
        schedule_tick(command)

      when SendMessage
        if command.delay.positive?
          schedule_delayed_message(command)
        else
          handle_message(command.message)
        end

      when EnterAltScreenCommand
        @program.enter_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, true) if @renderer_id
        @in_alt_screen = true

      when ExitAltScreenCommand
        @program.exit_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, false) if @renderer_id
        @in_alt_screen = false

      when SetWindowTitleCommand
        Bubbletea._set_window_title(command.title)

      when PutsCommand
        warn "\r#{command.text}\r"

      when SuspendCommand
        suspend_process

      when ExecCommand
        exec_process(command)

      when Proc
        Thread.new do
          result = command.call
          next unless result

          if result.is_a?(Message)
            queue_message(result)
          else
            process_command(result)
          end
        end
      end
    end

    def execute_command_sync(command)
      return if command.nil?

      case command
      when QuitCommand
        @running = false

      when BatchCommand
        execute_batch_sync(command.commands)

      when SequenceCommand
        execute_sequence_sync(command.commands)

      when TickCommand
        schedule_tick(command)

      when SendMessage
        sleep(command.delay) if command.delay.positive?
        handle_message(command.message)

      when EnterAltScreenCommand
        @program.enter_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, true) if @renderer_id
        @in_alt_screen = true

      when ExitAltScreenCommand
        @program.exit_alt_screen
        @program.renderer_set_alt_screen(@renderer_id, false) if @renderer_id
        @in_alt_screen = false

      when SetWindowTitleCommand
        Bubbletea._set_window_title(command.title)

      when PutsCommand
        warn "\r#{command.text}\r"

      when SuspendCommand
        suspend_process

      when ExecCommand
        exec_process(command)

      when Proc
        result = command.call
        return unless result

        if result.is_a?(Message)
          queue_message(result)
        else
          execute_command_sync(result)
        end
      end
    end

    def execute_sequence_sync(commands)
      commands.each do |cmd|
        break unless @running

        execute_command_sync(cmd)
      end
    end

    def execute_batch_sync(commands)
      threads = commands.map do |cmd|
        Thread.new { execute_command_sync(cmd) }
      end

      threads.each { |t| t.join }
    end

    def schedule_tick(tick_command)
      @pending_ticks << {
        at: Time.now + tick_command.duration,
        callback: tick_command.callback,
      }
    end

    def schedule_delayed_message(send_command)
      @pending_ticks << {
        at: Time.now + send_command.delay,
        message: send_command.message,
      }
    end

    def process_ticks
      now = Time.now
      ready, @pending_ticks = @pending_ticks.partition { |tick| tick[:at] <= now }

      ready.each do |tick|
        if tick[:callback]
          result = tick[:callback].call
          handle_message(result) if result
        elsif tick[:message]
          handle_message(tick[:message])
        end
      end
    end

    def suspend_process
      @program.disable_mouse if @options[:mouse_cell_motion] || @options[:mouse_all_motion]
      @program.show_cursor
      @program.stop_input_reader
      @program.exit_raw_mode

      Process.kill("TSTP", Process.pid)

      # When we get here, we've been resumed (SIGCONT was received)
      @program.enter_raw_mode
      @program.hide_cursor
      @program.start_input_reader
      @program.enable_mouse_cell_motion if @options[:mouse_cell_motion]
      @program.enable_mouse_all_motion if @options[:mouse_all_motion]

      handle_message(ResumeMessage.new)
    end

    def exec_process(command)
      @program.disable_mouse if @options[:mouse_cell_motion] || @options[:mouse_all_motion]
      @program.show_cursor
      @program.stop_input_reader
      @program.exit_raw_mode

      command.callable.call

      @program.enter_raw_mode
      @program.hide_cursor
      @program.start_input_reader
      @program.enable_mouse_cell_motion if @options[:mouse_cell_motion]
      @program.enable_mouse_all_motion if @options[:mouse_all_motion]

      handle_message(command.message) if command.message
    end

    def render
      return if @options[:without_renderer]
      return unless @renderer_id

      view = @model.view
      @program.render(@renderer_id, view)
    end
  end

  def self.run(model, **options)
    runner = Runner.new(model, **options)
    runner.run
  end
end

# ---- lib/bubbletea.rb -------------------------------------------------------------

module Bubbletea
  class Error < StandardError; end
end
