require_relative 'string'

class Object
  # Gets the class "name" and creates the class if necessary using
  # base as the super class
  # @param name [String] The string is modified {String#camelcase}ing
  #   it.
  # @param base [Class] If the desired class does not exist, it is
  #   creating using +base+ as its superclass.
  def get_class(name, base)
    # Doing this with eval causes the inherited class method of the
    # base (usually Item) to be called with class that has a name.
    # Otherwise, the classname is something like
    # #<Class:0x1234567890abcdef>
    name = name.camelcase
    eval("class ::#{name} < #{base}; end") unless ::Object.const_defined?(name)
    ::Object.const_get(name)
  end
end
