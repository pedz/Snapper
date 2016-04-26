require_relative 'logging'
require_relative "parse_error"
require 'pathname'

#
# The main driving routine for snaps.  I assume a similar class will
# be done for perf pmr data.
#
class SnapParser
  include Logging
  # Default log level is INFO
  LOG_LEVEL = Logger::INFO

  # @param dir [String, Pathname] The starting directory to walk
  #   down.  Pathname.find |path| is then called.
  # @param prune [Regexp] A regular express of directories not to
  #   traverse.  @see Find::find
  # @param db [Db] The database to populate during the parse.
  # @param patterns [Array<Array(Regexp, Class)>] An array of tuples of
  #   a regular expression that is matched against the pathname of the
  #   files found and the class to call to parse those files if the
  #   regular expression matches.  This list is created by calls to
  #   {Snapper.add_file_parsing_patterns}.  A duck type way of saying
  #   the above: patterns.each should result in elements that respond
  #   to first and last.  If first.match(path) returns true, then
  #   last.parse(io, db) will be called where io is the open file for
  #   path.
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
        @patterns.each do |regexp, parser|
          if regexp.match(path.to_s)
            path.open("r:ISO-8859-1") do |io|
              begin
                logger.debug { "parsing #{path} with #{parser.name}" }
                parser.new(io, @db, path).parse
              rescue ParseError => e
                e.add_message("path: #{path}")
                raise e
              end
            end
          end
        end
      end
    end
    self
  rescue ParseError => e
    pretty_parse_error(e)
    exit(1)
  end

  private

  def pretty_parse_error(e)
    $stderr.puts e.message
  end
end
