require "spec_helper"
require "logging"

describe Logging do
  after(:each) { Logging.reset_state }

  def make_class
    if $number
      $number += 1
    else
      $number = 1
    end
    eval <<-EOF
      class ::C#{$number}
        include Logging
        LOG_LEVEL = Logger::DEBUG
        self
      end
    EOF
  end

  it "should create a class logger method in the class that includes it" do
    klass = make_class
    expect(klass.respond_to?(:logger)).to be true
  end

  it "should create a class logger= method in the class that includes it" do
    klass = make_class
    expect(klass.respond_to?(:logger=)).to be true
  end

  it "should provide a logger instance method" do
    klass = make_class
    inst = klass.new
    expect(inst.respond_to?(:logger)).to be true
  end

  it "should use the class declared LOG_LEVEL as the default logging level" do
    klass = make_class
    inst = klass.new
    expect(inst.logger.level).to eq(Logger::DEBUG)
  end

  it "should use $stderr and Logger::INFO as its defaults" do
    orig_stderr = $stderr
    stringio = StringIO.new
    $stderr = stringio
    class T2
      include Logging
    end
    expect(T2.logger.level).to eq(Logger::INFO)
    T2.logger.info("test")
    expect(stringio.string).to eq("T2: test\n")
    $stderr = orig_stderr
  end

  describe "Logging.set_new_logger" do
    it "should change the logger if called after the class has been created" do
      klass = make_class
      inst = klass.new
      stringio = StringIO.new
      Logging.set_new_logger(klass.name, stringio, Logger::WARN)
      inst.logger.unknown("test")
      expect(inst.logger.level).to eq(Logger::WARN)
      expect(stringio.string).to eq("#{klass.name}: test\n")
    end

    it "should change the logger if called after the class and logger have been created" do
      klass = make_class
      inst = klass.new
      expect(inst.logger.level).to eq(Logger::DEBUG)
      Logging.set_new_logger(klass.name, nil, Logger::WARN)
      expect(inst.logger.level).to eq(Logger::WARN)
    end

    it "should change the logger if called before the class has been created" do
      Logging.set_new_logger("T1", nil, Logger::WARN)
      class ::T1
        include Logging
        LOG_LEVEL = Logger::DEBUG
      end
      inst = T1.new
      expect(inst.logger.level).to eq(Logger::WARN)
    end

    it "should have no effect if called with arguments of nil" do
      klass = make_class
      inst = klass.new
      expect(inst.logger.level).to eq(Logger::DEBUG)
      Logging.set_new_logger(klass.name, nil, nil)
      expect(inst.logger.level).to eq(Logger::DEBUG)
    end
  end

  describe "Logging.set_new_loggers" do
    it "should change all classes" do
      klass1 = make_class
      klass2 = make_class
      klass3 = make_class
      inst1 = klass1.new
      inst2 = klass2.new
      inst3 = klass3.new
      stringio = StringIO.new
      Logging.set_new_loggers(stringio, Logger::WARN)
      inst1.logger.unknown("test")
      expect(inst1.logger.level).to eq(Logger::WARN)
      expect(inst2.logger.level).to eq(Logger::WARN)
      expect(inst3.logger.level).to eq(Logger::WARN)
      expect(stringio.string).to eq("#{klass1.name}: test\n")
    end
    
    it "should recreate all loggers for all including modules" do
      klass1 = make_class
      klass2 = make_class
      klass3 = make_class
      inst1 = klass1.new
      inst2 = klass2.new
      inst3 = klass3.new
      expect(inst1.logger.level).to eq(Logger::DEBUG)
      expect(inst2.logger.level).to eq(Logger::DEBUG)
      expect(inst3.logger.level).to eq(Logger::DEBUG)
      Logging.set_new_loggers(nil, Logger::WARN)
      expect(inst1.logger.level).to eq(Logger::WARN)
      expect(inst2.logger.level).to eq(Logger::WARN)
      expect(inst3.logger.level).to eq(Logger::WARN)
    end
    
    it "should let individual Logging.set_new_logger called after Logging.set_new_loggers to take effect" do
      klass1 = make_class
      klass2 = make_class
      klass3 = make_class
      inst1 = klass1.new
      inst2 = klass2.new
      inst3 = klass3.new
      expect(inst1.logger.level).to eq(Logger::DEBUG)
      expect(inst2.logger.level).to eq(Logger::DEBUG)
      expect(inst3.logger.level).to eq(Logger::DEBUG)
      Logging.set_new_loggers(nil, Logger::WARN)
      Logging.set_new_logger(klass1.name, nil, Logger::DEBUG)
      expect(inst1.logger.level).to eq(Logger::DEBUG)
      expect(inst2.logger.level).to eq(Logger::WARN)
      expect(inst3.logger.level).to eq(Logger::WARN)
    end

    it "should have no effect if called with arguments of nil" do
      klass1 = make_class
      klass2 = make_class
      klass3 = make_class
      inst1 = klass1.new
      inst2 = klass2.new
      inst3 = klass3.new
      expect(inst1.logger.level).to eq(Logger::DEBUG)
      expect(inst3.logger.level).to eq(Logger::DEBUG)
      Logging.set_new_loggers(nil, nil)
      expect(inst1.logger.level).to eq(Logger::DEBUG)
      expect(inst2.logger.level).to eq(Logger::DEBUG)
      expect(inst3.logger.level).to eq(Logger::DEBUG)
    end

    it "should work on classes including Logging after the call to it" do
      Logging.set_new_loggers(nil, Logger::WARN)
      klass1 = make_class
      inst1 = klass1.new
      expect(inst1.logger.level).to eq(Logger::WARN)
    end
  end
end
