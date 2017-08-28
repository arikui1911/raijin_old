require 'optparse'

class Raijin
  class Error < RuntimeError ; end

  def self.run(argv, program: nil, stdout: $stdout, stderr: $stderr)
    cli = new()
    cli.__send__ :raijin_initialize, stdout, stderr
    runner = Runner.new(cli, program)
    runner.run argv
  end

  Command = Struct.new(:name, :desc, :options)

  def self.commands
    @commands ||= {}
  end

  attr_reader :stdout, :stderr

  private

  def raijin_initialize(stdout, stderr)
    @stdout = stdout
    @stderr = stderr
  end

  def command_nothing
    raise Error, 'nothing command'
  end

  def command_missing(name)
    raise Error, "invalid command - `#{name}'"
  end

  # Returning true means a order to show help.
  def handle_error(program, e)
    stderr.puts "#{program}: Error - #{e.message}"
    true
  end

  def self.last_command
    @last_command ||= Command.new(nil, nil, [])
  end

  def self.desc(str)
    last_command.desc = str.to_s
  end

  def self.option(*args, &block)
    last_command.options << [args, block]
  end

  def self.method_added(name)
    last_command.name = name
    commands[name] = last_command
    @last_command = nil
  end

  class Runner
    def initialize(cli, program = nil)
      @cli = cli
      @assigned_prgram = program
      reset_parser
    end

    attr_reader :program

    def run(argv)
      rest = @parser.order(argv)
      @cli.__send__(:command_nothing) if rest.empty?
      cmd_name = normalize_command_name(rest.shift)
      return help(*rest) if cmd_name == :help
      cmd = fetch_command(cmd_name) or @cli.__send__(:command_missing, cmd_name)
      assign_command cmd
      rest = @parser.parse(rest)
      @cli.public_send(cmd.name, *rest)
    rescue Error, OptionParser::ParseError => e
      @cli.__send__(:handle_error, program, e) and @parser.parse('--help')
    end

    private

    def help(what = nil)
      case what
      when nil
        reset_parser
        @parser.parse('--help')
      when 'command', 'commands'
        @cli.stderr.puts @cli.class.commands.values.select{|c|
          @cli.respond_to?(c.name)
        }.map{|c|
          "#{program} #{c.name}: #{c.desc}"
        }
      else
        cmd = fetch_command(normalize_command_name(what)) or raise(Error, "invalid help topic - `#{what}'")
        reset_parser
        assign_command cmd
        @parser.parse('--help')
      end
    end

    def reset_parser
      @parser = OptionParser.new
      @parser.program_name = @assigned_prgram if @assigned_prgram
      @program = @parser.program_name
      global = @cli.class.commands[:initialize] and assign_command(global)
    end

    def normalize_command_name(raw)
      raw.tr('-', '_').intern
    end

    def fetch_command(name)
      @cli.respond_to?(name) and @cli.class.commands[name.to_sym]
    end

    def assign_command(cmd)
      if cmd.name == :initialize
        me  = program
        arg = "COMMAND ..."
      else
        me  = "#{program} #{cmd.name}"
        arg = generate_args_desc(cmd.name)
      end
      @parser.banner = "#{me}: #{cmd.desc}\nUsage: #{me} [options] #{arg}"
      cmd.options.each do |(args, block)|
        @parser.on(*args){|*a| instance_exec(*a, &block) }
      end
    end

    def generate_args_desc(meth)
      @cli.method(meth).parameters.map{|(type, name)|
        name = name.upcase
        case type
        when :req
          name
        when :opt
          "[#{name}]"
        when :rest
          "[#{name}...]"
        when :keyreq, :key, :keyrest, :block
          nil
        else
          raise Exception, 'must not happen'
        end
      }.compact.join(' ')
    end
  end
end




__END__
class Hoge < Raijin
  desc "Easy RSS aggregater."
  option '--state=PATH', 'assign state file path' do |path|
  end
  def initialize
  end

  desc "List something up."
  def show_list
  end

  private

  def app
  end
end

Hoge.run(['--state=hoge', 'help', 'commands', 'hoge'], program: 'aggrss')

