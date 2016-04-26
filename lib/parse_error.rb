
class ParseError < RuntimeError
  def initialize(text, history)
    @history = history
    @text = [ text ]
  end

  def add_message(text)
    @text.insert(1, text)
  end

  def message
    [ @text, "", "Context:", @history, "", "Stack", self.backtrace[0 .. 5] ].flatten.join("\n")
  end
end
