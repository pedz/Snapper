require 'logger'

# This logging module creates a logger per class that include it.
# Both class and instance methods within the same class will have
# access to the same Logger via the logger method.  This leaves the
# door open for a lot of features such as different classes logging to
# different files as well as the ability to set per class logging
# level which could be done from the command line.
module Logging
  def self.included(base)
    class << base
      ##
      # :singleton-method:
      # The .logger method is available from class methods and is
      # actually where all the work takes place.
      def logger
        unless @logger
          @logger = Logger.new($stderr)
          @logger.formatter = proc { |sev, datetime, progname, msg|
            "#{msg}\n"
          }
          if self.const_defined?(:LOG_LEVEL)
            @logger.level = self.const_get(:LOG_LEVEL)
          end
        end
        @logger
      end
      
      ##
      # :singleton-method:
      # The logger may be assigned to a new logging instance.
      def logger=(logger)
        @logger = logger
      end
    end
  end
  
  # The #logger method is also available from any instance method and
  # calls to Logging.logger.
  def logger
    self.class.logger
  end
end
