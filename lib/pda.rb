
class PDA
  include Logging
  LOG_LEVEL = Logger::INFO

  class Production
    include Logging
    LOG_LEVEL = Logger::INFO
    
    def initialize(regexp, states = :all, new_state = :no_change, &block)
      raise "Bad Block" unless block.arity == 2
      @regexp = Regexp.new(regexp)
      @block = block
      @valid_states = states
      @new_state = new_state
    end
    
    def match(line, pda)
      current_state = pda.state
      return false unless (@valid_states == :all) || (@valid_states.include?(current_state))
      return false unless (md = @regexp.match(line))
      @block.call(md, pda)
      pda.state = @new_state unless @new_state == :no_change
      return true
    end

    def to_s
      @regexp.to_s
    end
  end

  attr_accessor :target
  # TODO: These are too specific and need to be generalized
  attr_accessor :single_field_pop_states, :empty_line_pop_states

  def initialize(first_target, productions)
    @state = :normal
    @stack = []
    @target = first_target
    @single_field_pop_states = 0
    @empty_line_pop_states = 0
    @productions = productions
  end

  def match_productions(line)
    logger.debug { "match_productions: #{@state}; #{@stack.size}; line: '#{line}'" }
    @productions.any? do |prod|
      if prod.match(line, self)
        logger.debug { "Matched: #{prod}"}
      end
    end
  end

  def stack
    @stack
  end

  def state
    @state
  end

  def state=(new_state)
    logger.debug { "new state: #{new_state}" }
    @state = new_state
  end

  def push(new_target)
    logger.debug { "pushing state #{@state}" }
    @stack.push([@target, @state])
    @target = new_target
  end

  def pop(cnt = 1)
    if cnt > 0
      @stack.pop(cnt - 1)
      @target, @state = @stack.pop
      logger.debug { "pop #{cnt} #{cnt > 1 ? "states" : "state" }; new state is #{@state}" }
    end
  end
end
