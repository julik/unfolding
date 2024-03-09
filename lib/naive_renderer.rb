require "stringio"

class NaiveRenderer
  def node_to_fragments(node, cache_store)
    if node.children.empty?
      ["<#{node.name} id=#{node.id} />"]
    else
      [
        "<#{node.name} id=#{node.id}>",
        node.children.map {|child| node_to_fragments(child, cache_store) },
        "</#{node.name}>"
      ]
    end
  end
end
