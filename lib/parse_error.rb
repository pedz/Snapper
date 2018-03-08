
class ParseError < RuntimeError
  def self.from_exception(e, history)
    return e if e.is_a?(ParseError)

    n = ParseError.new(e.message, history)
    n.set_backtrace(e.backtrace)
    n.set_class(e)
    n
  end

  def initialize(text, history)
    @history = history
    @text = [ text ]
    @klass = self.class
  end

  def add_message(text)
    @text.insert(1, text)
  end

  def message
    [ @text, "", "Context:", @history, "", "Stack", self.backtrace[0 .. 5] ].flatten.join("\n")
  end

  def class
    @klass
  end

  def set_class(e)
    @klass = e.class
  end
end
