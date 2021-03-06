require_relative 'logging'

# A PrintList is a List where each Item also has an associated
# priority that determines the order (lowest to highest) by which the
# items get printed.
class PrintList
  # Initializes a new Printlist
  def initialize
    @list = List.new
  end

  # Adds an item along with its associated priority to the print list
  # @param item [Item] The item to add
  # @param priority [Integer] The place to add the item in the print
  #   list.  Currenlty there are not guidelines for this.
  def add(item, priority)
    @list.push({item: item, priority: priority })
    self
  end

  # @return [Array<Item>] the items sorted by priority (low to high)
  def items
    @list.sort { |a, b| a[:priority] <=> b[:priority] }.map { |a| a[:item] }
  end

  # Print the list of items in the order of their priority (lowest to
  # highest).
  # @param context [Context] the context to use for printing.
  def print(context)
    items.print(context)
  end
end
