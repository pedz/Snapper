require 'logger'

# When this module is included, it creates two class instance methods:
# base.logger and base.logger=.  It also creates an instance method
# #logger in the class that includes it.  Both class and instance
# methods within the same class will have access to the same Logger
# via the logger method.  This leaves the door open for a lot of
# features such as different classes logging to different files as
# well as the ability to set per class logging level which could be
# done from the command line.
module Logging
  class << self
    # Sets the logdev and loglvl for all classes that include Logging
    # either before or after the call to set_new_loggers.
    def set_new_loggers(logdev, loglvl)
      @logdev = logdev if logdev
      @loglvl = loglvl if loglvl
      children.keys.each do |name|
        set_new_logger(name, @logdev, @loglvl)
      end
    end

    # Sets the logdev and loglvl for the logger in the named class.  If
    # the class already exists, the new values are installed.  In
    # either case, a record is made if the class should include
    # Logging at a later time.
    def set_new_logger(name, logdev, loglvl)
      v = children[name] || {}
      v[:logdev] = logdev if logdev
      v[:loglvl] = loglvl if loglvl
      children[name] = v
      if (::Object.const_defined?(name) &&
         (klass = ::Object.const_get(name)) &&
         klass.class == Class &&
         klass.respond_to?(:logger=))
        klass.logger = new_logger(name, logdev, loglvl)
      end
    end
    
    # Creates a new logger.  The logdev and loglvl can come from three
    # places.  In order of priority:
    #
    # 1. A call to set_new_logger or set_new_loggers causes children
    #    to be set with values.  Those take first priority
    #
    # 2. The logdev and loglvl passed in
    #
    # 3. The built in defaults of $stderr, and Logger::INFO.
    #
    def new_logger(name, logdev, loglvl)
      logdev = [ global_logdev(name), logdev, $stderr ].find { |e| e }
      loglvl = [ global_loglvl(name), loglvl, Logger::INFO ].find { |e| e }
      logger = Logger.new(logdev)
      logger.level = loglvl
      logger.formatter = proc { |sev, datetime, progname, msg|
        "#{name}: #{msg}\n"
      }
      children[name] = { logdev: logdev, loglvl: loglvl }
      logger
    end

    ##
    # :singleton-method: base.logger
    #
    # The ::logger method is created as a class method in the class
    # that included Logging and is available from class methods.  It
    # creates a new logger if there is no current logger.  The log
    # level is set to the LOG_LEVEL constant for the class that
    # included Logger.  The return value is the current logger.

    ##
    # :singleton-method: base.logger=
    #
    # The ::logger= method is created as a class method in the class
    # that included Logging and is also available to class methods of
    # the class that included Logger.  It assigns the argument as the
    # current logger.


    # Called when Logging is included in another module or class.  The
    # documentation assumes the including entity is a class but the
    # code does not.  base is set to the class that is including
    # Logging.
    #
    # If a new class is created after the set_new_logger is called,
    # this will install the new arguments to the logger in the class.
    # We also need to remember the classes in order for
    # set_new_loggers to work.
    def included(base)
      class << base
        # See comments in base.logger above
        def logger
          unless @logger
            if self.const_defined?(:LOG_LEVEL)
              loglvl = self.const_get(:LOG_LEVEL)
            else
              loglvl = nil
            end
            @logger = Logging.new_logger(self.name, nil, loglvl)
          end
          @logger
        end

        # See comments in base.logger= above
        def logger=(logger)
          @logger = logger
        end
      end
    end

    # This is provided for testing purposes to clear all of the
    # previous global state that has been created.
    def reset_state
      @children = nil
      @logdev = nil
      @loglvl = nil
    end

    private

    # If name is found in children, then the logdev for the entry is
    # returned otherwise, @logdev is returned.  Note that @logdev
    # starts out as nil and is set by a call to set_new_loggers.
    def global_logdev(name)
      if v = children[name]
        v[:logdev]
      else
        @logdev
      end
    end

    # If name is found in children, then the loglvl for the entry is
    # returned otherwise, @loglvl is returned.  Note that @loglvl starts
    # out as nil and is set by a call to set_new_loggers.
    def global_loglvl(name)
      if v = children[name]
        v[:loglvl]
      else
        @loglvl
      end
    end

    def children
      @children ||= {}
    end
  end
  
  # The #logger method is also available from any instance method of
  # the class that included Logging.  This calls the class instance
  # method base.logger.
  def logger
    self.class.logger
  end
end
