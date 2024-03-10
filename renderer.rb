require_relative "lib/node"
require_relative "lib/cache_store"
require_relative "lib/naive_renderer"
require_relative "lib/depth_first_renderer"
require_relative "lib/batched_depth_first_renderer"
require_relative "lib/breadth_first_renderer"
require_relative "lib/indented_print"

def render_with(renderer)
  rng = Random.new(42)
  b = Node::Builder.new
  root_node = b.node("Level1") do
    3.times do
      b.node("Level2") do
        3.times do
          b.node("Level3")
        end
      end
    end
  end

  warn "== #{renderer}:"

  cache = CacheStore.new

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== First render (cold cache) required #{r} roundtrips, cache state #{cache}"

  cache.evict_matching(/^Level1/)
  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== Second render (warm cache just without root node) required #{r} roundtrips, cache state #{cache}"

  # Evict some keys
  cache.evict_matching(/^Level1/)
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
  # render_with(NaiveRenderer.new)
  render_with(DepthFirstRenderer.new)
  render_with(BatchedDepthFirstRenderer.new)
  render_with(BreadthFirstRenderer.new)
end
