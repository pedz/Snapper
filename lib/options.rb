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

  # @return [Array<String>] The list of snaps to process
  attr_accessor :dir_list

  # @return [Boolean] true if the -D flag was given on the command
  #   line.  Default is false.
  attr_reader :dump
  
  # @return [Boolean] true if the --interactive command line option
  #   was specified and false otherwise.
  attr_reader :interactive
  
  # @return [-1 .. 11] The level indicated by the -l option on the
  #   command line.  The default is 1.
  attr_reader :level

  # @return [Boolean] True if the -k option was given on the command
  #   line.  The default is false.
  attr_reader :print_keys
  
  # @return [File] The file to write the html file out to.  The
  #   default is that this is nil and the text output is done.  When
  #   this is set, the text output is not done.
  attr_reader :html

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
  attr_reader :output

  # @param program_name [String] The name of the program.
  def initialize(program_name = File.basename($0))
    @dir_list = []
    @dump = false
    @html = nil
    @interactive = false
    @level = 1
    @one_file = true
    @output = $stdout
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

  private

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
              "Output verbosity level from -1 to 11",
              "default is 1") do |l|
        if l < -1 || l > 11
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

      opts.on("-q file",
              "Sets the file that the Quick debug goes to",
              "default is $stderr") do |path|
        $qb = File.open(path, "w")
      end

      opts.on("-h path",
              "--html path",
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

      opts.on("--interactive",
              "Drops the user into an irb session") do |interactive|
        @interactive = interactive
      end
    end
  end
end
