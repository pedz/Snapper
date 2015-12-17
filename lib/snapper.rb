require 'zlib'
require 'pathname'
require_relative 'logging'
require_relative 'options'
require_relative 'snap'
require_relative 'batch'

# A class that represents the snapper program
class Snapper
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
  
  class << self
    ##
    # A class can add itself as a snap_processor by calling
    # Snapper.add_snap_processor(self).  The class must have a
    # +create+ method which is called passing it a Snap as its only
    # argument.  See Seas.create as an example.
    def add_snap_processor(klass)
      logger.debug { "add_snap_processor #{klass}"}
      snap_processors.push(klass)
    end

    ##
    # A class can add itself as a batch_processor by calling
    # Snapper.add_batch_processor(self).  The class must have a
    # +create+ method which is called passing it a Batch as its only
    # argument.
    def add_batch_processor(klass)
      batch_processors.push(klass)
    end

    ##
    # A class can add itself as a parser by adding calling
    # Snapper.add_file_parsing_patterns pass in a hash whose keys are
    # regular expressions that match files and values are the classes
    # to call to parse them.  The class is passed an IO and a db.
    # FileParser is often the super class of file parsers.
    def add_file_parsing_patterns(hash)
      hash.each_pair do |regexp, parser|
        file_parsers[regexp] = parser
      end
    end

    def current_instance=(instance)
      @current_instance = instance
    end

    def add_command_line_option
      fail "Snapper.add_command called at an odd time" if @current_instance.nil?
      yield *@current_instance
    end

    private
    
    # Returns the list of snap processors
    def snap_processors
      @snap_processors ||= []
    end
    
    # Returns the list of batch processors
    def batch_processors
      @batch_processors ||= []
    end

    # Returns the list of file parsers
    def file_parsers
      @file_parsers ||= {}
    end
  end

  def initialize
    @options = Options.new(File.basename($0))
    help = OptionParser::Officious.delete('help') 
    @options.version = [ 1, 0, 0 ]
    @options.release = "a"
    @options.banner = @options.banner + " <path to snap1> [ <path to snap2> ... ]"
    OptionParser::Officious['help'] = help
  end

  # Now the main program.
  #
  # We load and process the options but ignore any errors so that any
  # logging can be turned on as early as possible
  def run
    first_option_parse
    load_files
    second_option_parse
    create_batch
    run_batch_processors
    do_cmd
  end

  # Needed to get interactive to work
  def to_s
    "Sample"
  end

  private
  
  # Options are parsed in two stages.  As early as possible, the
  # options are parsed so the various debugging and logging options
  # can be set as early as possible.  Then the files are loaded which
  # may define new options.  A second parse of the options is then
  # done and then the general processing is done.
  def first_option_parse
    @args = []
    begin
      @options.order!(ARGV) do |opt|
        @args << opt
      end
    rescue OptionParser::InvalidOption => e
      e.recover(ARGV)
      @args << ARGV.shift
      retry
    rescue => e
      @options.abort(e.message)
    end
    @options.add_officious
  end

  def second_option_parse
    begin
      @options.parse!(@args)
      raise OptionParser::MissingArgument.new("<path to snap1>") if @options.dir_list.empty?
    rescue => e
      @options.abort(e.message)
    end
  end

  def load_files
    Snapper.current_instance = [ self, @options ]
    Pathname.glob(Pathname.new(__FILE__).parent.realpath + "**/*.rb") do |f|
      require_relative f
    end
    Snapper.current_instance = nil
  end

  ##
  # Passed the command line options
  # def initialize(options)
  #   @options = options
  # end

  # Processes the list of snaps probably best described in
  # Phases[index.html#label-Phases].
  def create_batch
    snap_list = @options.dir_list.map do |path|
      logger.debug { "Processing #{path}"}
      path = Pathname(path)
      snap = nil
      if path.directory?
        if dump_path(path).file?
          snap = restore(dump_path(path))
        else
          db = Db.new
          SnapParser.new(path, nil, db, file_parsers).parse
          snap = Snap.new({ dir: path, db: db })
          if @options.dump
            dump(path, snap)
          end
        end
      elsif path.file?
        snap = restore(path)
      else
        $stderr.puts "snapper.rb: #{path} is not a directory nor a snapper dump"
        exit 1
      end

      snap_processors.each do |klass|
        logger.debug { "calling snap_processor for #{klass}"}
        klass.create(snap)
      end
      snap
    end

    @batch = Batch.new(snap_list)
  end

  def run_batch_processors
    batch_processors.each do |klass|
      logger.debug { "calling batch_processor for #{klass}"}
      klass.create(@batch)
    end
  end

  def do_cmd
    # @options.cmds.each { |cmd| cmd.call(@batch, @options) }
    if @options.print_keys
      print_keys
    elsif @options.html
      html
    elsif @options.interactive
      interactive
    else
      print
    end
  end

  # Returns the list of file parsers to the instance
  def file_parsers
    self.class.send :file_parsers
  end

  # Returns the list of snap processors to the instance
  def snap_processors
    self.class.send :snap_processors
  end

  # Returns the list of batch processors to the instance
  def batch_processors
    self.class.send :batch_processors
  end

  # Returns the path to the marshal dump file
  def dump_path(path)
    path + ".ruby.dump.gz"
  end

  # calls Marhal.dump to marshal out a two item array.  The first item
  # is the list from Item.children.  The second item is snap
  def dump(path, snap)
    Zlib::GzipWriter.open(dump_path(path), 9) do |gz|
      Marshal.dump([ Item.children, snap ], gz)
    end
  end

  # The marshaled entity is two element array.  The first element is
  # an array of class names that subclassed Item.  The second element
  # is the OpenStruct which we called snap.  The proc finds the first
  # array during the deserializing and then scans that array of
  # strings creating classes.  This occurs before any of the snap is
  # scanned.  Thus the classes created during the parsing are
  # recreated before the snap is scanned.
  def restore(path)
    Zlib::GzipReader.open(path) do |gz|
      done = false
      p = Proc.new  { |obj|
        if (done == false) && (obj.class == Array)
          obj.each do |classname|
            ::Object.const_set(classname, Class.new(Item)) unless ::Object.const_defined?(classname)
          end
          done = true
        end
        obj
      }
      class_array, result = Marshal.restore(gz, p)
      result
    end
  rescue => e
    $stderr.puts "snapper.rb: Can not restore from #{path}: #{e.message}"
    exit 1
  end

  def print_keys
    @options.puts(@batch.snap_list[0].db.keys.sort)
  end

  def html
    Page.new(@batch, @options.html, @options.one_file).create_page
  end

  def print
    @batch.print(Context.new(@options))
  end

  def interactive
    require 'irb'
    IRB.setup(nil)
    workspace = IRB::WorkSpace.new(binding)
    irb = IRB::Irb.new(workspace)
    IRB.conf[:MAIN_CONTEXT] = irb.context
    irb.eval_input
  end
end
