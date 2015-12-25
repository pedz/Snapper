
# I am not sure I am going to keep this.  I thought it might be a good
# idea to allow users to do:
#   foo.a.b.c.d == 22
# and even if a or b or c or d do not exist, the code would not blow
# up but would still return false.  But it turns out that while this
# trick does not cause the program to blow up, it still causes the
# output to be confused unless the programmer is careful and it hides
# errors making it harder for the programmer to be careful.
class EmptyItem < BasicObject
  def method_missing(method, *args, &proc)
    return nil.send(method, *args, &proc) if nil.respond_to?(method)
    return self if proc.nil? && args.length == 0
    $stderr.puts(method)
    $stderr.puts(nil.respond_to?(method))
    super
  end

  def respond_to_missing?(method, include_private = false)
    nil.respond_to?(method) or super
  end
end
