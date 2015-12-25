
class String
  # Basically the normal snakecase that converts FooBar into foo_bar
  # but also converts any non-word characters into underscores and
  # then replaces a sequence of underscores with just one underscore.
  def snakecase
    self.
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z0-9])([A-Z]+)/, '\1_\2').
      gsub(/\W+/, "_").
      gsub(/__+/, "_").
      downcase
  end

  # Call {#snakecase} and then splits the result at the underscore
  # characters, capitalizing each one, and then joining them
  # together.  e.g. "lsattr -El ent0" becomes "LsattrElEnt0".
  def camelcase
    self.
      snakecase.
      split('_').
      map(&:capitalize).
      join
  end
end
