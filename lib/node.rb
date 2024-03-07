require "base64"

class Node
  class Builder
    def initialize
      @children = []
    end

    def node(name)
      previous_children, @children = @children, []

      yield if block_given?

      Node.new(name, @children).tap do |this_node|
        previous_children << this_node
        @children = previous_children
      end
    end
  end

  attr_reader :name, :id, :children
  ID_DISPENCER = (0..).each

  def initialize(name, children=[])
    @name = name
    @id = ID_DISPENCER.next
    @children = children
  end

  def self.gen_n(n, name)
    n.times.map { new(name) }
  end

  def cache_key
    "#{@name}/#{@id}"
  end
end
