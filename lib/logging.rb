require 'logger'

# This logging module creates a logger per class that include it.
# Both class and instance methods within the same class will have
# access to the same Logger via the logger method
module Logging
  def self.included(base)
    class << base
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
      
      def logger=(logger)
        @logger = logger
      end
    end
  end
  
  def logger
    self.class.logger
  end
end
