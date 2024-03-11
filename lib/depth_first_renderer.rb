require "stringio"

class DepthFirstRenderer
  def node_to_fragments(node, cache_store)
    if fragments = cache_store.read(node.cache_key)
      return fragments
    end

    if node.children.empty?
      ["<#{node.name} id=#{node.id} />"]
    else
      child_fragments = node.children.map do |child|
        node_to_fragments(child, cache_store)
      end
      [
        "<#{node.name} id=#{node.id}>",
        child_fragments,
        "</#{node.name}>"
      ]
    end.tap do |fragments|
      cache_store.write(node.cache_key, fragments)
    end
  end
end
