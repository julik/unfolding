require "stringio"

class BatchedDepthFirstRenderer
  def node_to_fragments(node, cache_store)
    if node.children.empty?
      ["<#{node.id} />"]
    else
      child_cache_keys = node.children.map(&:cache_key)
      cached_fragments_for_children = cache_store.read_multi(child_cache_keys)
      child_fragments = cached_fragments_for_children.zip(node.children).map do |(maybe_cached, child)|
        if maybe_cached
          maybe_cached
        else
          child_fragments = node_to_fragments(child, cache_store)
          cache_store.set(child.cache_key, child_fragments)
          child_fragments
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
