require "base64"

class Node
  DEFAULT_ID_GENERATOR = (0..).each

  class Builder
    def initialize
      @ids = (0..).each
      @children = []
    end

    def node(name)
      previous_children, @children = @children, []
      yield if block_given?
      Node.new(name, @children, id_generator: @ids).tap do |this_node|
        previous_children << this_node
        @children = previous_children
      end
    end
  end

  attr_reader :name, :id, :children

  def self.build(name)
    b = Builder.new
    b.node(name) do
      yield(b) if block_given?
    end
  end

  def initialize(name, children = [], id_generator: DEFAULT_ID_GENERATOR)
    @name = name
    @id = id_generator.next
    @children = children
  end

  def cache_key
    "#{@name}-#{@id}"
  end
end
