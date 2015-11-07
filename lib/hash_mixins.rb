
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
# A mixin for a Hash subclass which mucks with the key making them
# valid method names.  Then missing_method is used so that the method
# name can be used as well as the original key name.  The technique
# used here defers creating the instance method until the first lookup
# since in this particular case, there are many more keys created than
# are level retrieved.
module HashMakeMethods
  def respond_to_missing?(method, include_all)
    find_name(method) || super
  end

  def method_missing(method, *args, &proc)
    if !block_given? && args.length == 0 && self.has_key?(method)
      return self[method]
    end
    super
  end

  def []=(key, value)
    super(fix_key(key), value)
  end

  def key?(key)
    super(fix_key(key))
  end

  def has_key?(key)
    super(fix_key(key))
  end

  def [](key)
    super(fix_key(key))
  end

  private

  def fix_key(key)
    key.to_s.downcase.gsub(/[^a-z0-9_]/, '_').to_sym
  end

  def find_name(method)
    self.has_key?(method) && method
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
