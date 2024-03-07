require "base64"

class Node
  attr_reader :id, :children
  def initialize(name, children=[], cached: true)
    @name = name
    @cached = true
    @id = random_id
    @children = children
  end

  def self.gen_n(n, name)
    n.times.map { new(name) }
  end

  def random_id
    Base64.strict_encode64(Random.bytes(4))
  end

  def cache_key
    return unless @cached
    "#{@name}/#{@id}"
  end
end
