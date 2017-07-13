require 'logger'

# This logging module creates one global Logger instance.  Each class
# will include Logging and then class and instance methods will be
# able to call a logger method to log messages.
module Logging
  class << self
    def logger
      @logger ||= Logger.new($stderr)
    end
      
    def logger=(logger)
      @logger = logger
    end
  end

  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end
  
  def logger
    Logging.logger
  end
end
