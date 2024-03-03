class Node
  attr_reader :id, :children
  def initialize(id, children=[])
    @id = id
    @children = children
  end

  def cache_key
    @id
  end
end
