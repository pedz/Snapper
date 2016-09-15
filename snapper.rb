#!/usr/bin/env ruby

require 'pathname'
require 'date'

# Load Snapper class and then call it
require_relative 'lib/snapper'

# "Quick Bug" -- used for quick printf style debugging.  The output
# file can be changed via the -q command.  The default is $stderr
$qb = $stderr
# Quick Bug does a puts to the quick bug output file passing it the
# args that it was passed.
# @param args [Array<Object>]
def qb(*args)
  $qb.puts(*args)
end

def foo(options = {})
  text = []
  text.push("--------------------")
  text.push("Date: #{DateTime.now}")
  text.push("User: #{ENV["USER"]}")
  text.push("Version: #{$snapper_version}")
  text.push("Release: #{$snapper_release}")
  text.push("Args: #{options[:args].inspect}")
  text.push("Cwd: #{Dir.pwd}")
  text.push("Status: #{options[:status]}")
  text.push("Message: #{options[:message]}") if options.has_key?(:message)
  text.push("Backtrace: \n#{options[:backtrace].join("\n")}") if options.has_key?(:backtrace)

  File.open((Pathname.new(__FILE__).parent + "log"), "a", 0622) do |f|
    f.puts(text.join("\n"))
  end
end

def log_user
  args = ARGV.dup
  Snapper.new.run
  exit(0)
rescue SystemExit => e
  foo(args: args, status: e.status)
  exit!(e.success?)
rescue => e
  $stderr.puts "Oh dear... A #{e.class} occurred"
  $stderr.puts "Message: #{e.message}"
  unless e.is_a? ParseError
    $stderr.puts "Backtrace (which you may not understand)\n#{e.backtrace.join("\n")}"
  end
  $stderr.puts "This should be logged and Perry will hopefully eventually see it and try to fix it."
  foo(args: args, status: 1, message: e.message, backtrace: e.backtrace)
  exit!(false)
end

$snapper_version = "%%% VERSION %%%"
$snapper_release = "%%% RELEASE %%%"
log_user
