require_relative "item"
require 'date'

# An attempt at a unified entity that captures what the output of
# lslpp provides.
class Lslpp
  # @return [String] The action which can be +APPLY+, +CLEANUP+,
  #   +COMMIT+, and +REJECT+.
  attr_reader :action

  # @return [String] The date as a string.
  attr_reader :date

  # @return [String] The description of the fileset or LPP.
  attr_reader :description

  # @return [String] Never seen this but it must be good!
  attr_reader :efix_locked

  # @return [String] The fileset name (or LPP name).
  attr_reader :fileset

  # @return [String] The +F+ of +VRMF+ (Version, Release,
  #   Modification, Fix).
  attr_reader :fix

  # @return [String] The +VRMF+ as reported by the lslpp command.
  #   This is a tad hard to use because it does not easily sort.
  attr_reader :level

  # @return [String] The +M+ of +VRMF+ (Version, Release,
  #   Modification, Fix).
  attr_reader :mod

  # @return [String] The lpp, history, and inventory files can live in
  #   three different directories that I know of: /etc/objrepos and
  #   /usr/lib/objrepos, /usr/share/lib/objrepos.
  attr_reader :path

  # @return [String] The PTF Id.
  attr_reader :ptf_id

  # @return [String] The +R+ of +VRMF+ (Version, Release,
  #   Modification, Fix).
  attr_reader :rel

  # @return [String] The state which can be such things as +APPLIED+
  #   and +COMMITTED+ but also +APPLYING+.
  attr_reader :state

  # @return [String] The status which can be +BROKEN+, +CANCELED+, and
  #   +COMPLETE+.
  attr_reader :status

  # @return [String] The time field as a string.
  attr_reader :time

  # @return [String] +I+ if the latest level came from an install
  #   image or +F+ if the latest level came from an update image.
  attr_reader :type

  # @return [String] The +V+ of +VRMF+ (Version, Release,
  #   Modification, Fix).
  attr_reader :ver

  # @return [Hash] The original hash of options
  attr_reader :options

  def initialize(options)
    @options     = options

    @action      = options["action"]      || "Unknown"
    @date        = options["date"]        || "Unknown"
    @description = options["description"] || "Unknown"
    @efix_locked = options["efix locked"] || "Unknown"
    @fileset     = options["fileset"]     || "Unknown"
    @level       = options["level"]       || "Unknown"
    @path        = options["path"]        || "Unknown"
    @ptf_id      = options["ptf id"]      || "Unknown"
    @state       = options["state"]       || "Unknown"
    @status      = options["status"]      || "Unknown"
    @time        = options["time"]        || "Unknown"
    @type        = options["type"]        || "Unknown"

    v, r, m, f = @level.split('.')
    @ver = v.to_i
    @rel = r.to_i
    @mod = m.to_i
    @fix = f.to_i
    unless @time == "Unknown" || @date == "Unknown"
      @time = @time.gsub(';', ':')
      m, d, y = @date.split('/').map(&:to_i)
      if y < 80
        y += 2000
      else
        y += 1900
      end
      @date_time = DateTime.parse("#{m}/#{d}/#{y} #{@time}")
    end
  end

  # @return [String] An eaiser form of the vrmf (or level) printed in
  #   a consistent, comparable format of 00.00.0000.0000
  def vrmf
    "%02d.%02d.%04d.%04d" % [ @ver, @rel, @mod, @fix ]
  end
end
