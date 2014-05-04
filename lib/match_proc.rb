
class MatchProc
  def initialize(regexp, states = :all, new_state = :nc, &block)
    raise "Bad Block" unless block.arity == 3
    @regexp = Regexp.new(regexp)
    @block = block
    @states = states
    @new_state = new_state
  end

  def match(line, ret, state, obj)
    return false unless (@states == :all) || (@states.include?(state[0]))
    return false unless (md = @regexp.match(line))
    @block.call(md, ret, obj)
    state[0] = @new_state unless @new_state == :nc
    return true
  end
end
