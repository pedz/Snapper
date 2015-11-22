require 'optparse'
require 'ostruct'
require 'zlib'
require_relative 'logging'

# A class that represents the snapper program
class Snapper
  include Logging
  LOG_LEVEL = Logger::INFO      # The log level for the Snapper class
  
  class << self
    def add_klass(klass)
      klasses.push(klass)
    end

    def klasses
      @klasses ||= []
    end

    def add_patterns(hash)
      hash.each_pair do |regexp, parser|
        patterns[regexp] = parser
      end
    end

    def patterns
      @patterns ||= {}
    end
  end
  
  def initialize(options)
    @options = options
  end

  # Called with dir_list set to an array of directories.  Each
  # directory should point to the top of a snap.
  def run
    snap_list = @options.dir_list.map do |path|
      path = Pathname(path)
      snap = nil
      if path.directory?
        if dump_file(path).file?
          Zlib::GzipReader.open(dump_file(path)) do |gz|
            snap = restore(gz.read)
          end
        else
          db = Db.new
          SnapParser.new(path, nil, db, patterns).parse
          snap = OpenStruct.new({ dir: path, db: db, alerts: [], print_list: PrintList.new })
          if @options.dump
            Zlib::GzipWriter.open(dump_file(path), 9) do |gz|
              Marshal.dump([ Item.children, snap ], gz)
            end
          end
        end
      elsif path.file?
        restore(path.read)
      end

      Snapper.klasses.each { |klass| klass.create(snap) }
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
      snap.print_list.items.print(Context.new(@options))
    end
  end

  private

  def patterns
    self.class.patterns
  end
  
  def dump_file(path)
    @dump_file ||= (path + ".ruby.dump.gz")
  end

  ##
  # The marshaled entity is two element array.  The first element is
  # an array of class names that subclassed Item.  The second element
  # is the OpenStruct which we called result.  The proc finds the
  # first array during the deserializing and then scans that array of
  # strings creating classes.  This occurs before any of the result is
  # scanned.  Thus the classes created during the parsing are
  # recreated before the result is scanned.
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
