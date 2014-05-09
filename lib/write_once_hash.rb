
# A hash but a value can only be written once.
class WriteOnceHash < Hash
  include Logging

  def []=(field, value)
    fail "Overwriting value #{field}" if key?(field)
    logger.debug "Adding field: #{field} = #{value}"
    super
  end
end
