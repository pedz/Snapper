require 'pathname'
require 'optparse'
require 'forwardable'
require_relative 'logging'

# The options that snapper.rb can accept
class Options
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  extend Forwardable

  # @!macro [attach] def_delegator
  #   @!method $2
  #     Forwards to $1.
  #     @see OptParser#$2
  def_delegator :opt_parser, :order!
  def_delegator :opt_parser, :on
  def_delegator :opt_parser, :on_head
  def_delegator :opt_parser, :on_tail
  def_delegator :opt_parser, :help
  def_delegator :opt_parser, :add_officious
  def_delegator :opt_parser, :banner
  def_delegator :opt_parser, :banner=
                             true # Added to keep emacs formatting happy
  def_delegator :opt_parser, :program_name
  def_delegator :opt_parser, :abort
  def_delegator :opt_parser, :release
  def_delegator :opt_parser, :release=
                             true # Added to keep emacs formatting happy
  def_delegator :opt_parser, :version
  def_delegator :opt_parser, :version=
                             true # Added to keep emacs formatting happy
  
  # @!macro [attach] def_delegator
  #   @!method $2(*args)
  #     Forwards to $1.
  #     @see IO#$2
  def_delegator :output, :puts
  def_delegator :output, :printf

  # @return [Boolean] The argument given to --color.  +:auto+ means to
  #   colorize if the output is a tty (even when being sent to a
  #   pager).  +:never+ means to never colorize.  +:always+ means to
  #   always colorize.  Default is :auto
  # attr_reader :colorize

  # @return [Array<String>] The list of snaps to process
  attr_accessor :dir_list

  # @return [Boolean] true if the -D flag was given on the command
  #   line.  Default is false.
  attr_reader :dump
  
  # @return [File] The file to write the html file out to.  The
  #   default is that this is nil and the text output is done.  When
  #   this is set, the text output is not done.
  attr_reader :html

  # @return [Boolean] true if the --interactive command line option
  #   was specified and false otherwise.
  attr_reader :interactive
  
  # @return [-1 .. 11] The level indicated by the -l option on the
  #   command line.  The default is 1.
  attr_reader :level

  # @return [Boolean] True if --one-file was given on the command line
  #   and false if the --no-one-file was given.  The html file can be
  #   done in two ways.  The css and javascript can be included into
  #   the file.  This makes it easy to move the file around and the
  #   output still works.  Or, the css and javascript can be pulled in
  #   when the page is loaded.  This makes debugging the css and
  #   javascript much easier.  The default is --one-file.
  attr_reader :one_file
  
  # @return [File] Returns the file which text output should be sent.
  #   Defaults to $stderr but may be altered by the +-o+ command line
  #   argument.
  # attr_reader :output

  # @return [String] The argument given to --pager.  Used as a path to
  #   the pager to invoke.  Default is nil
  # attr_accessor :pager

  # @return [Boolean] True if -p or --paginate given on the command
  #   line and False if --no-pager.  Defaults to true.
  # attr_accessor :paginate

  # @return [Boolean] True if the -k option was given on the command
  #   line.  The default is false.
  attr_reader :print_keys
  
  # @param program_name [String] The name of the program.
  def initialize(program_name = File.basename($0))
    @colorize = :auto
    @dir_list = []
    @dump = false
    @html = nil
    @interactive = false
    @level = 3
    @one_file = true
    @output = $stdout
    @pager = nil
    @paginate = true
    @print_keys = false
    @program_name = program_name
  end

  # Parse the arguments but does not modify them.
  # @param args [Array<String>] The arguments to parse.
  # @return [Options] self
  def parse(args)
    opt_parser.parse(args)
    self
  end

  # Parse and modify the arguments.  Also fills out {#dir_list} with
  # the unused arguments.
  # @param args [Array<String>] The arguments to parse.
  # @return [Options] self
  def parse!(args)
    opt_parser.parse!(args)
    while args.length > 0
      @dir_list.push(args.shift)
    end
    self
  end

  # The name will likely change.  Adds +cmd+ to the list that needs to
  # be executed.
  # @param cmd [Proc] the command to add to the list
  def add_cmd(cmd)
    cmds << cmd
  end

  # @return [Array<Proc>] returns the current list of commands.
  def cmds
    @cmds ||= []
  end

  # @return [Boolean] true if output should be colorized and false
  #   otherwise.
  def colorize
    @once ||= setup_pager
    @colorize
  end

  # @return [IO] Returns the I/O handler the output stream.
  def output
    @once ||= setup_pager
    @output
  end

  private

  # Determines proper setting for colorize and output.
  def setup_pager
    if @paginate && @output.isatty && @html.nil?
      env = {}
      @pager = ENV["SNAPPER_PAGER"] if @pager.nil?
      @pager = ENV["PAGER"] if @pager.nil?
      @pager = "less" if @pager.nil?

      # Set less options unless LESS already set in environment
      if @pager == "less"
        # -F or --quit-if-one-screen
        # -R or --RAW-CONTROL-CHARS
        # -S or --chop-long-lines
        # -X or --no-init
        env["LESS"] = "FRSX" unless ENV["LESS"]
      end
      @output = IO.popen(env, [ "sh", "-c", @pager ], "w")
      @colorize = !(@colorize == :never)
    else
      @colorize = (@colorize == :always)
    end
    true
  end

  # Creates the OptionsParser along with many of the command's
  # arguments.
  def opt_parser
    @opt_parser ||= OptionParser.new do |opts|
      opts.program_name = @program_name
      opts.on("-D",
              "--dump",
              "For each snap, creates a .ruby.dump.gz file",
              "at the base directory of the snap with the",
              "parse tree of the snap.  This file will be",
              "automatically loaded instead of re-parsing",
              "the files within the snap.") do |d|
        @dump = d
      end

      opts.on(:REQUIRED,
              "-L [class:]level[:path]",
              "--LOG [class:]level[:path]",
              "If no class is specified, sets the log",
              "level for all loggers and optionally the",
              "log file. If a class is specified, sets the",
              "log level and optionally the log file for",
              "the specified class.  level can be 0, 1, 2,",
              "3, 4, DEBUG, INFO, WARN, ERROR, or FATAL.",
              "path may be a path to a file that is opened",
              "in append mode, \"STDERR\", or \"STDOUT\".",
              "Multiple -L options can be specified and",
              "are processed in order.  The default level",
              "is INFO (1) and the default output is",
              "STDERR.") do |arg|
        words = arg.split(':')
        klass = nil
        new_level = nil
        loop do
          case words[0]
          when "DEBUG", "0"
            new_level = Logger::DEBUG
            break
          when "INFO", "1"
            new_level = Logger::INFO
            break
          when "WARN", "2"
            new_level = Logger::WARN
            break
          when "ERROR", "3"
            new_level = Logger::ERROR
            break
          when "FATAL", "4"
            new_level = Logger::FATAL
            break
          else
            klass = words.shift
          end
        end
        path = words[1]
        case path
        when "STDERR"
          path = $stderr
        when "STDOUT"
          path = $stdout
        end
        if klass
          Logging.set_new_logger(klass, path, new_level)
        else
          Logging.set_new_loggers(path, new_level)
        end
      end

      opts.on("-k",
              "--print-keys",
              "Print the top level keys of the first snap") do |k|
        @print_keys = k
      end

      opts.on("-l N",
              "--level N",
              Integer,
              "Output verbosity level from 0 to 11",
              "default is 3") do |l|
        if l < 0 || l > 11
          raise OptionParser::InvalidArgument.new(l)
        end
        @level = l
      end

      opts.on("-o file",
              "--output file",
              "Specify an output file",
              "Default is STDOUT") do |path|
        @output = File.open(path, "w")
      end

      opts.on("--news",
              "Prints new items added to snapper") do |not_used|
        self.puts (Pathname.new(__FILE__).parent.parent + "News").readlines
        output.close
        exit(0)
      end

      opts.on("-q file",
              "Sets the file that the Quick debug goes to",
              "default is $stderr") do |path|
        $qb = File.open(path, "w")
      end

      opts.on("--html path",
              "Outputs an html file that shows the layout",
              "of the systems") do |path|
        if path.nil?
          path = "snapper.html"
        else
          unless /\.html$/.match(path)
            path += ".html"
          end
        end
        @html = File.open(path, "w")
      end

      opts.on("--[no-]one-file",
              "Embed (the default --one-file) the",
              "Javascript and CSS files into the HTML",
              "output or (--no-one-file) keep them",
              "separate.") do |v|
        @one_file = v
      end

      opts.on("--color=[never | always | auto]",
              [:never, :always, :auto],
              "Decorate output with colors",
              "Default is auto"
             ) do |p|
        @colorize = p
      end
      
      opts.on("--no-color",
              "Same as --color=never") do |p|
        @colorize = :never
      end

      opts.on("-p",
              "--paginate",
              "Pipes output into $SNAPPER_PAGER, or $PAGER, or less") do |p|
        @paginate = true
      end
 
      opts.on("--pager=PAGER",
              "Pipes output to PAGER") do |p|
        @pager = p
      end
      
      opts.on("--no-pager",
              "Do not invoke the pager") do |p|
        @paginate = false
      end

      opts.on("--interactive",
              "Drops the user into an irb session") do |interactive|
        @interactive = interactive
      end

      opts.on("--legend",
              "Prints the meaning of the various ethernet attributes") do |not_used|
        self.puts <<'EOF'

        Key   - Meaning
        ----- - -------
        nnnG  - Port speed in Gbps e.g. 10G
        nnnM  - Port speed in Mbps e.g. 100M
        AA    - Alternate MAC address
        C4    - Checksum offload for TCP carried by IPv4
        DEAD  - Adapter marked as DEAD
        C6    - Checksum offload for TCP carried by IPv6
        L6    - Large send (TSO) for TCP carried by IPv6
        LR    - Large receive
        L4    - Large send (TSO) for TCP carried by IPv4
        LIMBO - Limbo state is usually due to link down
        PM    - Promiscuous mode
        VF    - Virtual Port which I believe is a SEA, VEA,
                or an ether channel made up of virtual ports

EOF
        output.close
        exit(0)
      end
    end
  end
end
