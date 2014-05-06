
class MatchProc
  def initialize(regexp, states = :all, new_state = :no_change, &block)
    raise "Bad Block" unless block.arity == 2
    @regexp = Regexp.new(regexp)
    @block = block
    @valid_states = states
    @new_state = new_state
  end

  def match(line, env)
    # we can not cache up the value of env[:stack].last because the proc might push or pop it
    current_state = env[:stack].last[:state]
    return false unless (@valid_states == :all) || (@valid_states.include?(current_state))
    return false unless (md = @regexp.match(line))
    @block.call(md, env)
    env[:stack].last[:state] = @new_state unless @new_state == :no_change
    return true
  end
end
