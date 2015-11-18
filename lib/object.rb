
class Object
  ##
  # Gets the class "name" and creates the class if necessary using
  # base as the super class
  def get_class(name, base)
    # Doing this with eval causes the inherited class method of the
    # base (usually Item) to be called with class that has a name.
    # Otherwise, the classname is something like
    # #<Class:0x1234567890abcdef>
    name = name.gsub(/ /, '').gsub(%r{[^a-zA-Z0-9]},'_').capitalize
    eval("class ::#{name} < #{base}; end") unless ::Object.const_defined?(name)
    ::Object.const_get(name)
  end
end
