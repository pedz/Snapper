require 'optparse'
require 'forwardable'
require_relative 'logging'

# The options that snapper.rb can accept
class Options
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # def order!(*args, &proc)
  #   opt_parser.order!(*args, &proc)
  # end

  extend Forwardable
  def_delegators :opt_parser, :order!, :on, :on_head, :on_tail, :help,
                 :add_officious, :banner, :banner=, :program_name,
                 :abort, :release, :release=, :version, :version=

  ##
  # The list of snaps to process
  attr_accessor :dir_list

  ##
  # true if the -D flag was given on the command line.  Default is
  # false.
  attr_reader :dump
  
  ##
  # true if the --flat_keys flag was given on the command line.  The
  # default is false.
  attr_reader :flat_keys

  ##
  # If the --interactive command line option was specified, this flag
  # will be true and false otherwise.
  attr_reader :interactive
  
  ##
  # The level indicated by the -l option on the command line.  The
  # default is 1.  Valid values are -1 up to 11.
  attr_reader :level

  ##
  # True if the -k option was given on the command line.  The default
  # is false.
  attr_reader :print_keys
  
  ##
  # The path to write the html file out to.  The default is that this
  # is nil and the text output is done.  When this is set, the text
  # output is not done.
  attr_reader :html

  ##
  # The html file can be done in two ways.  The css and javascript can
  # be included into the file.  This makes it easy to move the file
  # around and the output still works.  Or, the css and javascript can
  # be pulled in when the page is loaded.  This makes debugging the
  # css and javascript much easier.  The default is --one-file.
  attr_reader :one_file
  
  def initialize(program_name)
    @dir_list = []
    @dump = false
    @flat_keys = false
    @html = nil
    @interactive = false
    @level = 1
    @one_file = true
    @output = $stdout
    @print_keys = false
    @program_name = program_name
  end

  # Parse the arguments
  def parse(args)
    opt_parser.parse(args)
    self
  end

  # Parse and modify the arguments
  def parse!(args)
    opt_parser.parse!(args)
    while args.length > 0
      @dir_list.push(args.shift)
    end
    self
  end

  # Does a puts with the specified arguments to the output file
  # specified.  The default output file is $stdout.
  def puts(*args)
    @output.puts(*args)
  end

  # Does a printf with the specified arguments to the output file
  # specified.  The default output file is $stdout.
  def printf(*args)
    @output.printf(*args)
  end

  def add_cmd(cmd)
    cmds << cmd
  end

  def cmds
    @cmds ||= []
  end

  private

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
              "--print_keys",
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

      # opts.on("--flat-keys",
      #         "Print the flat_keys and value of the entire",
      #         "database from the first snap.") do |flat_keys|
      #   @flat_keys = flat_keys
      # end

      opts.on("--interactive",
              "Drops the user into an irb session") do |interactive|
        @interactive = interactive
      end
    end
  end
end
