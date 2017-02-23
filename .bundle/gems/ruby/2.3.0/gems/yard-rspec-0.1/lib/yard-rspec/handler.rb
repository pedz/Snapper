# The assumption is that the describe will have either two arguments
# or be nested two deep with Class and #method being the two levels.
# This allows the P in the +it+ handler to find the method.
class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
  handles method_call(:describe)
  
  def process
    objname = statement.parameters.first.jump(:string_content).source
    # if statement.parameters[1]
    #   src = statement.parameters[1].jump(:string_content).source
    #   objname += (src[0] == "#" ? "" : "::") + src
    # end
    obj = {
      spec: (owner ? (owner[:spec] || "") : ""),
      context: ""
    }
    obj[:spec] += objname

    parse_block(statement.last.last, owner: obj)
  rescue YARD::Handlers::NamespaceMissingError
  end
end

# Within the two +describe+ nestings and around all of the +it+ blocks
# can be an optional set of +context+ nestings.
class RSpecContextHandler < YARD::Handlers::Ruby::Base
  handles method_call(:context)
  
  def process
    return unless statement.is_a?(YARD::Parser::Ruby::MethodCallNode)
    context = statement.parameters.first.jump(:string_content).source
    # If owner does not have a :spec, then this context is not within
    # the describe.
    # @todo add nested context support
    obj = {
      spec: (owner ? (owner[:spec] || "") : ""),
      context: context
    }

    parse_block(statement.last.last, owner: obj)
  rescue YARD::Handlers::NamespaceMissingError
  end
end

class RSpecItHandler < YARD::Handlers::Ruby::Base
  handles method_call(:it)
  
  def process
    return if owner.nil?
    obj = P(owner[:spec])
    return if obj.is_a?(Proxy)
    
    # @todo can not cope with "one-liner" syntax
    #   it { is_expected.to respond_to(:foo_dog) }
    return if statement.parameters.first.nil?

    name = statement.parameters.first.jump(:string_content).source
    file = statement.file
    line = statement.line
    source = statement.last.last.source.chomp
    h = {
      name: name,
      file: file,
      line: line,
      source: source
    }

    obj[:specifications] ||= {}
    (obj[:specifications][owner[:context]] ||= []) << h
  end
end
