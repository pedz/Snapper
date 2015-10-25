require_relative 'logging'
require 'pathname'

#
# The main driving routine for snaps.  I assume a similar class will
# be done for perf pmr data.
#
class SnapParser
  include Logging
  LOG_LEVEL = Logger::INFO

  # dir is a string or a Pathname of the starting directory to walk
  # down.  Pathname.find |path| is then called.
  #
  # If prune.match(path) returns true, the path will be pruned (via
  # Find.prune).
  #
  # db is passed as the second argument to the parse methods (keep
  # reading).
  #
  # patterns.each should result in elements that respond to first and
  # last.  If first.match(path) returns true, then last.parse(io, db)
  # will be called where io is the open file for path.
  def initialize(dir, prune, db, patterns)
    @dir, @prune, @db, @patterns = dir, prune, db, patterns
  end

  # parse the files within the directory (@dir) using the patterns and
  # adding the items to the database
  def parse
    Pathname.new(File.expand_path(@dir)).find do |path|
      if @prune && @prune.match(path.to_s)
        Find.prune
      end
      if path.file?
        @patterns.each do |ele|
          if ele.first.match(path.to_s)
            path.open("r:ISO-8859-1") do |io|
              ele.last.new(io, @db).parse
            end
          end
        end
      end
    end
    self
  end
end
