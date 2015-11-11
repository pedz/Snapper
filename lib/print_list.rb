require_relative 'logging'

class PrintList
  def initialize
    @list = []
  end

  def add(item, priority)
    @list.push({item: item, priority: priority })
    self
  end

  def items
    @list.sort { |a, b| a[:priority] <=> b[:priority] }.map { |a| a[:item] }
  end
end
