require_relative "lib/node.rb"
require_relative "lib/cache_store.rb"
require_relative "lib/depth_first_renderer.rb"
require_relative "lib/batched_depth_first_renderer.rb"
require_relative "lib/breadth_first_renderer.rb"
require_relative "lib/indented_print.rb"

def render_with(renderer)
  rng = Random.new(42)
  b = Node::Builder.new
  root_node = b.node("Forum") do
    b.node("Header")
    b.node("Thread") do
      b.node("Thread") do
        b.node("Thread") do
          320.times { b.node("Post") }
        end
        b.node("Thread") do
          620.times { b.node("Post") }
        end
        b.node("Thread") do
          640.times { b.node("Post") }
        end
        b.node("Thread") do
          240.times do
            b.node("Post") do
              b.node("Avatar")
            end
          end
        end
      end
      b.node("Thread")
    end
  end

  warn "== #{renderer}:"
  
  cache = CacheStore.new

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== First render (cold cache) required #{r} roundtrips, cache state #{cache}"

  cache.evict_matching(/^Forum/)
  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== Second render (warm cache) required #{r} roundtrips, cache state #{cache}"

  # Evict some keys
  cache.evict_matching(/^Forum/)
  cache.evict_ratio(0.5, random: rng)

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== Third render (half of keys evicted) required #{r} roundtrips, cache state #{cache}"

  cache.evict_matching(/^Forum/)

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== Fourth render (no eviction) required #{r} roundtrips, cache state #{cache}"
  warn "\n"
end

if __FILE__ == $0
  render_with(DepthFirstRenderer.new)
  render_with(BatchedDepthFirstRenderer.new)
  render_with(BreadthFirstRenderer.new)
end