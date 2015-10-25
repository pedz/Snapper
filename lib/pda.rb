require_relative 'logging'

# A very simple but effective push down automata.
class PDA
  include Logging
  LOG_LEVEL = Logger::INFO      # The logging level used by PDA

  # Represents the production statements in a classical PDA.  These
  # can change states as well as push and pop items onto a stack.
  class Production
    include Logging
    LOG_LEVEL = Logger::INFO # The logging level used by PDA::Production
    
    # Creates the production.  regexp is a regular expression or a
    # string.  states is the set of states that the production is
    # valid in.  The special symbol :all means that it is valid in all
    # states.  new_state is the state to move to.  :no_change is a
    # special value that means the state is not changed.  block is
    # yielded to if the regular expression match and is passed the
    # match data of the match and the parent PDA.
    def initialize(regexp, states = :all, new_state = :no_change, &block)
      raise "Bad Block" unless block.arity == 2
      @regexp = Regexp.new(regexp)
      @block = block
      @valid_states = states
      @new_state = new_state
    end
    
    # Called with a line of text and the parent PDA.  If the current
    # state of the PDA is not within the set of valid states for this
    # production or if the regular expression within the production
    # does not match the line of text, match simply returns false.
    # Otherwise the saved with the Production is yielded to passing it
    # the match data and the parent PDA.  When it returns, if
    # new_state is not :no_change, then the parent PDA's state is
    # changed to the Production's new_state and returns true.
    def match(line, pda)
      current_state = pda.state
      return false unless (@valid_states == :all) || (@valid_states.include?(current_state))
      return false unless (md = @regexp.match(line))
      @block.call(md, pda)
      pda.state = @new_state unless @new_state == :no_change
      return true
    end

    # Currently returns the regular expression as a string.  I believe
    # this is only used for debugging purposes.
    def to_s
      @regexp.to_s
    end
  end

  # Probably a very bad name and poorly implemented.  The block within
  # the productions can use this as a scratch pad to keep state
  # variables and other things.  This is passed in to the
  # initialize method.
  attr_accessor :target

  # Initializes the PDA with the initial value of the "target" and the
  # list of productions.
  def initialize(first_target, productions)
    @state = :normal
    @stack = []
    @target = first_target
    @productions = productions
  end

  # Determines if any of the productions matches the line of text.
  # The first hit terminates the search.  Returns true if there was a
  # hit and false otherwise.
  def match_productions(line)
    logger.debug { "match_productions: #{@state}; #{@stack.size}; line: '#{line}'" }
    @productions.any? do |prod|
      if prod.match(line, self)
        logger.debug { "Matched: #{prod}"}
      end
    end
  end

  # accessor to the stack used by the PDA.
  def stack
    @stack
  end

  # Assigns a new state
  def state=(new_state)
    logger.debug { "new state: #{new_state}" }
    @state = new_state
  end

  # Accessor to the current state of the PDA.
  def state
    @state
  end

  # pushes the current target onto the stack along with the current
  # state and sets target equal to the new_target.
  def push(new_target)
    logger.debug { "pushing state #{@state}" }
    @stack.push([@target, @state])
    @target = new_target
  end

  # Pops cnt levels off the stack assigning the current state and
  # target to the value that is now the new top of the stack.
  def pop(cnt = 1)
    if cnt > 0
      @stack.pop(cnt - 1)
      @target, @state = @stack.pop
      logger.debug { "pop #{cnt} #{cnt > 1 ? "states" : "state" }; new state is #{@state}" }
    end
  end
end
