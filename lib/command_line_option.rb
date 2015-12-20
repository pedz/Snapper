require_relative "snapper"

class CommandLineOption
  # Calls Snapper.add_command_line_option and yields options
  def CommandLineOption.command_line_option(&block)
    Snapper.add_command_line_option(&block)
  end
end
