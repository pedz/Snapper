require_relative "snapper"

module Kernel
  # Calls Snapper.add_command_line_option and yields options
  def command_line_option(&block)
    Snapper.add_command_line_option(&block)
  end
end
