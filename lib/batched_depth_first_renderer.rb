require "stringio"

class BatchedDepthFirstRenderer
  def node_to_fragments(node, cache_store)
    if node.children.empty?
      ["<#{node.name} id=#{node.id} />"]
    else
      child_cache_keys = node.children.map(&:cache_key)
      cached_fragments_for_children = cache_store.read_multi(child_cache_keys)

      to_write = {}
      child_fragments = cached_fragments_for_children.zip(node.children).map do |(maybe_cached, child)|
        if maybe_cached
          maybe_cached
        else
          to_write[child.cache_key] = node_to_fragments(child, cache_store)
        end
      end

      cache_store.write_multi(to_write) if to_write.any?

      [
        "<#{node.name} id=#{node.id}>",
        child_fragments,
        "</#{node.name}>"
      ]
    end
  end
end
