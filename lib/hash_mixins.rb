
##
# A mixin for Hash that causes the []= to fail if the key is already
# defined.
module HashWriteOnce
  ##
  # Fails if field is already a key in the Hash This tends to make
  # writing parsers a little easier because it is more clear on the
  # fields (or subfields) that are not being differentiated during the
  # parse.
  def []=(field, value)
    fail "Overwriting value #{field}" if key?(field)
    logger.debug { "Adding field: '#{field}' = '#{value}'" }
    super
  end
end

##
# A mixin for Hash that replaces []= so that a getter method is
# created for each hash key.
module HashMakeMethods
  def HashMakeMethods.included(mod)
    mod.const_set(:PREDEFINED_METHODS, mod.instance_methods)
  end

  ##
  # Assigns value to the key in the hash but also creates a method for
  # key to simplify tests, etc.  The method's name is the same as the
  # key except it is downcased and any non-alphanumerics are changed
  # to underscores.  If the method collides with a pre-existing
  # method, an underscore is added to it.
  def []=(key, value)
    method = key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
    predefined_methods = self.class.const_get(:PREDEFINED_METHODS)
    if predefined_methods.include?(method)
      method = ("_" + key.to_s.downcase.gsub(/[^a-z0-9_]/, '_')).to_sym
    end
    if self.respond_to?(method)
      fail "Collision with #{key} to #{method}" unless self.key?(key)
    else
      define_singleton_method(method) { self[key] }
    end
    logger.debug { "Adding field: '#{field}' = '#{value}'" }
    super
  end
end

##
# Combines HashWriteOnce and HashMakeMethods...
module HashWriteOnceMethods
  def HashMakeMethods.included(mod)
    mod.const_set(:PREDEFINED_METHODS, mod.instance_methods)
  end

  ##
  # Fails if key is already part of the hash.  Creates a method based
  # on the key.
  def []=(key, value)
    fail "Overwriting value #{field}" if key?(field)
    method = key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
    predefined_methods = self.class.const_get(:PREDEFINED_METHODS)
    if predefined_methods.include?(method)
      method = ("_" + key.to_s.downcase.gsub(/[^a-z0-9_]/, '_')).to_sym
    end
    define_singleton_method(method) { self[key] }
    logger.debug { "Adding field: '#{field}' = '#{value}'" }
    super
  end
end
