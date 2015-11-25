require_relative 'logging'

# A PrintList is a List where each Item also has an associated
# priority that determines when the item gets printed.
class PrintList
  # Initializes a new Printlist
  def initialize
    @list = List.new
  end

  # Adds an item along with its associated priority to the print list
  def add(item, priority)
    @list.push({item: item, priority: priority })
    self
  end

  # Returns the items sorted by priority (low to high)
  def items
    @list.sort { |a, b| a[:priority] <=> b[:priority] }.map { |a| a[:item] }
  end

  # Print the list of items in the order of their priority (lowest to
  # highest).
  def print(options)
    items.print(Context.new(options))
  end
end
