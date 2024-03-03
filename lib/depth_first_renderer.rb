require "stringio"

class DepthFirstRenderer
  def node_to_fragments(node, cache_store)
    if node.children.empty?
      ["<#{node.id} />"]
    else
      child_fragments = node.children.map do |child|
        if (cached = cache_store.get(child.cache_key))
          cached
        else
          node_to_fragments(child, cache_store).tap do |f|
            cache_store.set(child.cache_key, f) # We know all fragments have been expanded
          end
        end
      end
      [
          "<#{node.id}>",
          child_fragments,
          "</#{node.id}>"
      ]
    end
  end
end
