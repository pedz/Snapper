require 'logger'

# When this module is included, it creates two class instance methods.
# This logging module creates a logger per class that include it.
# Both class and instance methods within the same class will have
# access to the same Logger via the logger method.  This leaves the
# door open for a lot of features such as different classes logging to
# different files as well as the ability to set per class logging
# level which could be done from the command line.
module Logging
  ##
  # :singleton-method: base.logger
  #
  # The ::logger method is created as a class method in the class or
  # module that included the Logging module and is available from
  # class methods.  It creates a new logger if there is no current
  # logger.  The log level is set to the LOG_LEVEL constant for the
  # class or module that included the Logger module.  The return value
  # is the current logger.

  ##
  # :singleton-method: base.logger=
  #
  # The ::logger= method is created as a class method in the class or
  # module that included the Logging module and is also available to
  # class methods of the module or class that included Logger.  It
  # assigns the logger argument as the current logger.

  # Called when Logging is included in another module or class.  base
  # is set to the module or class that is including Logging.
  def self.included(base)
    # Opens the class up so methods can be attached to the class
    # instance.
    class << base
      # See comments in base.logger above
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

      # See comments in base.logger= above
      def logger=(logger)
        @logger = logger
      end
    end
  end
  
  # The #logger method is also available from any instance method of
  # the class or module that included Logging.  This calls the class
  # instance method base.logger.
  def logger
    self.class.logger
  end
end
