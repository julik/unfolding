class Node
  attr_reader :id, :children
  def initialize(name, children=[], cached: true)
    @name = name
    @cached = true
    @id = Random.bytes(2).unpack("H*")
    @children = children
  end

  def self.gen_n(n, name)
    n.times.map { new(name) }
  end

  def cache_key
    return unless @cached
    "#{@name}/#{@id}"
  end
end
