#!/usr/bin/env ruby

require_relative "lib/context.rb"
require 'ostruct'

context = Context.new(OpenStruct.new(level: 1), 6)

context.output("hi")
context.output("hi", [ :red ])
context.output("hi", [ :bold, :red, :nocr ])
context.output("there", [ :bold ])
context.output("hi", [ :bg, :red ])
context.output("hi", [ :nocr ])
context.output("there", [ :bg, :red ])
context.output("hi", [ :nocr ])
context.output(["there", "Suzy"], [ :red, :nocr ])
context.output
context.output([ "line", "line", "line", "line", "line"])
context.output("blah blah", [ :red, :bg, :blue ])
