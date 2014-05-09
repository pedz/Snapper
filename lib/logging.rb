require 'logger'

# This logging module creates a logger per class that include it.
# Both class and instance methods within the same class will have
# access to the same Logger via the logger method
module Logging
  def self.included(base)
    class << base
      def logger
        @logger ||= Logger.new($stderr)
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
