require 'zlib'
require 'pathname'
require_relative 'logging'

# A class that represents the snapper program
class Snapper
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO
  
  class << self
    ##
    # A class can add itself as a snap_processor by calling
    # Snapper.add_snap_processor(self).  The class must have a
    # +create+ method which is called passing it a snap as its only
    # argument.  See Seas.create as an example.
    def add_snap_processor(klass)
      snap_processors.push(klass)
    end

    ##
    # A class can add itself as a parser by adding calling
    # Snapper.add_file_parsing_patterns pass in a hash whose keys are
    # regular expressions that match files and values are the classes
    # to call to parse them.  The class is passed an IO and a db.
    # FileParser is often the super class of file parsers.
    def add_file_parsing_patterns(hash)
      hash.each_pair do |regexp, parser|
        file_parers[regexp] = parser
      end
    end

    private
    
    # Returns the list of snap processors
    def snap_processors
      @snap_processors ||= []
    end

    # Returns the list of file parsers
    def file_parers
      @file_parers ||= {}
    end
  end
  
  ##
  # Passed the command line options
  def initialize(options)
    @options = options
  end

  # Processes the list of snaps probably best described in
  # Phases[index.html#label-Phases].
  def run
    snap_list = @options.dir_list.map do |path|
      path = Pathname(path)
      snap = nil
      if path.directory?
        if dump_path(path).file?
          Zlib::GzipReader.open(dump_path(path)) do |gz|
            snap = restore(gz.read)
          end
        else
          db = Db.new
          SnapParser.new(path, nil, db, file_parers).parse
          snap = Snap.new({ dir: path, db: db })
          dump(path, snap) if @options.dump
        end
      elsif path.file?
        restore(path.read)
      end

      snap_processors.each { |klass| klass.create(snap) }
      snap
    end
    list = OpenStruct.new({ snap_list: snap_list, alerts: [] })

    # This section will be a sequence of calls that will rummage
    # around in the snap list either creating conveninece items or
    # adding alerts in various places.  In theory, it should be
    # possible to make this an extensible list.

    # From here down will be output routines
    if @options.print_keys
      puts snap_list[0][:db].keys.sort
      return
    end

    # put out the top level alerts first -- perhaps with splats.
    list.alerts.each do |alert|
      # print out alerts
    end

    # Then for each snap
    list.snap_list.each do |snap|
      snap.print(@options)
    end
  end

  private

  # Returns the list of file parsers to the instance
  def file_parers
    self.class.send :file_parers
  end

  # Returns the list of snap processors to the instance
  def snap_processors
    self.class.send :snap_processors
  end

  # Returns the path to the marshal dump file
  def dump_path(path)
    @dump_path ||= (path + ".ruby.dump.gz")
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
  def restore(io)
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
    class_array, result = Marshal.restore(io, p)
    result
  end
end
