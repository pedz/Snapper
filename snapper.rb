#!/usr/bin/env ruby

require_relative 'lib/snap_parser'
require_relative 'lib/odm'
require_relative 'lib/db'

unless ARGV.length == 1
  $stderr.puts "Usage: snapper <dir>"
  exit 1
end

Patterns = {
  %r{/general/([^.]*\.)(?!vc\.)add\z} => Odm # ODM files in general but not the vc files
}

SeaPdDvLn = "adapter/pseudo/sea"
db = Db.new

puts ARGV[0]
SnapParser.parse(ARGV[0], nil, db, Patterns)

l = db.table('CuDv').find_all { |cudv|
  cudv.PdDvLn == SeaPdDvLn
}.each { |sea|
  puts "Name: #{sea.name}"
  sea.attributes(db).each_pair { |k, v| puts "    #{k}: #{v}"}
}
