require_relative 'logging'

# A PrintList is a List where each Item also has an associated
# priority that determines when the item gets printed.
class PrintList
  def initialize
    @list = List.new
  end

  def add(item, priority)
    @list.push({item: item, priority: priority })
    self
  end

  def items
    @list.sort { |a, b| a[:priority] <=> b[:priority] }.map { |a| a[:item] }
  end
end
