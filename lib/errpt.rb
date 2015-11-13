require_relative "item"
require_relative 'logging'

class Errpt < Item
  def print(context)
    case context.options.level
    when 0
      # nothing
    when 1
      if context.state.nil?
        context.state = { count: 0 }
        context.proc = Proc.new do |context|
          output(context, "#{context.state[:count]} error log entries")
        end
      end
      context.state[:count] += 1
    when 2, 3, 4, 5
      text = "%*s %s" % [ -22, label, date_time ]

      if context.state.nil?
        context.state = {
          first: nil,
          last: nil,
          last_text: nil,
          count: -1,
        }
        context.proc = Proc.new do |context|
          state = context.state
          if state[:count] > 0
            output(context.nest, "#{state[:count]} duplicates removed")
          end
          output(context, state[:last_text])
          state[:last] = state[:last_text] = nil
          state[:count] = -1
        end
      end
      state = context.state
      if state[:first] && state[:first].label == label
        state[:count] += 1
        state[:last] = self
        state[:last_text] = text
      else
        if state[:last]
          context.proc.call(context)
        end
        output(context, text)
        state[:first] = self
      end
    else
      self.to_text.each_line do |line|
        output(context, line)
      end
    end
    context
  end
end
