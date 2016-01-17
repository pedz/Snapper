require_relative "item"

# ODM attributes are a pain.  It may be that the snap does not have
# the PdAt entries in which case, any field from the PdAt is not
# known.  It may be that the attribute is not customized in which case
# there are no CuAt values.  99% of there time, there is one PdAt
# entry and, if the attribute is customized, there is one CuAt entry.
# But there are instances of multiple PdAt entries for the same
# uniquetype and attribute (see model_map attribute for the
# disk/iscsi/nonmpiodisk uniquetype) as well as instances of multiple
# CuAt entries such as the route attribute for the inet0 device.
#
# This class tries to simplify matters while still providing access to
# the raw dirty details if required.
class Attribute
  # @param cu_ats [Array<Item>] The list of CuAt entries for this
  #   device and attribute combination -- usually an array of only one
  #   element.
  # @param pd_ats [Item, nil] The +PdAt+ entry for this device and
  #   attribute combination if available.
  def initialize(cu_ats = [], pd_ats = [])
    pd_ats = [] if pd_ats.nil?
    cu_ats = [] if cu_ats.nil?
    fail "Both cu_ats and pd_at can not be empty" if cu_ats.empty? && pd_ats.empty?
    @cu_ats = cu_ats
    @pd_ats = pd_ats
  end

  # @return [Array<Item>] The CuAt entries for this attribute.
  # @note This is an Array usually with zero or one elements but can
  #   be a list such as the +route+ attribute of +inet0+.
  def cu_ats
    @cu_ats ||= []
  end
  
  # @return [nil] If no customized (CuAt) entries.
  # @return [Item] The first (and usually only) CuAt entry for
  #   this attribute.
  def cu_at
    @cu_at ||= cu_ats[0]
  end

  # @return [Array<Item>] The PdAt entries with the same uniquetype.
  # @note This usually has zero or one elements but there are cases of
  #   multiple PdAt entries for the same attribute with the same
  #   uniquetype.
  def pd_ats
    @pd_ats ||= []
  end
  
  # @return [nil] If +PdAt+ not in snap.
  # @return [Item] The +PdAt+ entry for this attribute.
  def pd_at
    @pd_at ||= pd_ats[0]
  end

  # @return [Array<String, Integer>] Returns the +value+ field of the
  #   CuAt entries.
  # @note The +PdAt+ ODM entries also have a +values+ field which is
  #   the set of legal values for the attribute.  To access this
  #   field, use {#pd_at_values}.
  def values
    @values ||= @cu_ats.map(&:value)
  end

  # @return [Boolean] true if at least one value in values is not
  #   equal to the deflt value.
  def customized?
    default = deflt
    !(values.empty? || values.all? { |v| v == default })
  end
  
  # @return [nil] If no CuAt entries.
  # @return [String] The name of the device this attribute is
  #   associated with.
  def name
    cu_ats.empty? ? nil : cu_at.name
  end

  # @return [String, Integer] Returns the +value+ field from +CuAt+ if
  #   it is not nil; otherwise returns the +deflt+ field from the
  #   +PdAt+ value.
  def value
    cu_ats.empty? ? deflt : cu_at.value
  end

  # @return [nil] If no +PdAt+ entry in the snap.
  # @return [String] The +uniquetype+ field of the +PdAt+ entry.
  def uniquetype
    pd_at ? pd_at.uniquetype : nil
  end

  # @return [nil] If no +PdAt+ entry in the snap.
  # @return [String] The +deflt+ field of the +PdAt+ entry.
  def deflt
    pd_at ? pd_at.deflt : nil
  end

  # @return [nil] If no +PdAt+ entry in the snap.
  # @return [String] The +width+ field of the +PdAt+ entry.
  def width
    pd_at ? pd_at.width : nil
  end

  # @return [nil] If no +PdAt+ entry in the snap.
  # @return [String] The +values+ field of the +PdAt+ entry.
  def pd_at_values
    pd_at ? pd_at.values : nil
  end

  # @return [String] The +attribute+ field of either the +PdAt+ entry
  #   or the +CuAt+ entry.
  def attribute
    either.attribute
  end

  # @return [String] The +generic+ field of either the +PdAt+ entry or
  #   the +CuAt+ entry.
  def generic
    either.generic
  end

  # @return [String] The +nls_index+ field of either the +PdAt+ entry
  #   or the +CuAt+ entry.
  def nls_index
    either.nls_index
  end

  # @return [String] The +rep+ field of either the +PdAt+ entry
  #   or the +CuAt+ entry.
  # @note In some examples the rep of the CuAt entry does not match
  #   the rep in the matching PdAt entry.
  def rep
    either.rep
  end

  # @return [String] The +type+ field of either the +PdAt+ entry or
  #   the +CuAt+ entry.
  def type
    either.type
  end

  # @param options [Hash] The usual options passed to +to_json+.
  # @return [String] The JSON representation of the target.  The
  #   cu_ats and pd_ats as passed in at initialization time are added
  #   to a hash and converted to JSON.
  def to_json(options = {})
    {
      cu_ats: @cu_ats,
      pd_ats: @pd_ats
    }.to_json(options)
  end

  private

  # Used internally as a quick means to get a non-nil value that
  # contained the desired field.
  # @return [PdAt] If the PdAt entry was in the snap.
  # @return [CuAt] The first CuAt otherwise.
  def either
    @either = (pd_at || cu_at)
  end
end
