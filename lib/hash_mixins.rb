require_relative 'string'

# A mixin for Hash that causes the []= to fail if the key is already
# defined.
module HashWriteOnce
  # Fails if field is already a key in the Hash This tends to make
  # writing parsers a little easier because it is more clear on the
  # fields (or subfields) that are not being differentiated during the
  # parse.
  # @param field [String] The field to set in the hash.
  # @param value [Object] The value to set in the hash.
  # @raise ["Overwriting value <field>"] if field is already set in
  # the hash.
  # @raise [RuntimeError] if an existing field is overwritten.
  def []=(field, value)
    fail "Overwriting value #{field}" if key?(field)
    logger.debug { "Adding field: '#{field}' = '#{value}'" }
    super
  end
end

# A mixin for a Hash subclass which mucks with the key making them
# valid method names.  Then missing_method is used so that the method
# name can be used as well as the original key name.  The technique
# used here does not create a new method but just retrieve it via
# missing_method.  The reason is there are many more keys created than
# are ever retrieved.
module HashMakeMethods
  # @return [Boolean] Returns true if the method is defined.
  # @param method [Symbol] The symbol to check.
  # @param include_all [Boolean]
  def respond_to_missing?(method, include_all)
    find_name(method) || super
  end

  # Check to see if there is a key by the same name as symbol
  # @param method [Symbol] The method that was involved upon the
  #   target.
  # @param args [Array<Object>] The arguments passed.
  # @param proc [Proc] The proc (if any) that was passed.
  def method_missing(method, *args, &proc)
    if !block_given? && args.length == 0 && self.has_key?(method)
      return self[method]
    end
    # An alternative coding leveraging EmptyItem but I'm not sure I
    # really like it.
    # if !block_given? && args.length == 0
    #   return self[method] || EmptyItem.new
    # end
    super
  end

  # @param key [String] The field or key to set.
  # @param value [Object] The value to set the field to.
  # @return [Object] value is returned.
  def []=(key, value)
    super(fix_key(key), value)
  end

  # @return [Boolean] true if hash has an entry for +key+.
  # @param key [String] The key to look up.
  def key?(key)
    super(fix_key(key))
  end

  # (see #key?)
  def has_key?(key)
    super(fix_key(key))
  end

  # @param key [String] Returns the value in the hash for +key+.
  def [](key)
    super(fix_key(key))
  end

  private

  # @return [Symbol] Converts key into a usable method name by
  #   converting it to a string, snakecasing it, and then converting
  #   it to a Symbol.
  def fix_key(key)
    key.to_s.snakecase.to_sym
  end

  # @param method [Symbol] The symbol to see check the hash for.
  # @return [Boolean] returns true if hash has the method
  def find_name(method)
    self.has_key?(method) && method
  end
end
