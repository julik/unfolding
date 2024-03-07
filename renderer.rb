require_relative "lib/node.rb"
require_relative "lib/cache_store.rb"
require_relative "lib/depth_first_renderer.rb"
require_relative "lib/batched_depth_first_renderer.rb"
require_relative "lib/breadth_first_renderer.rb"
require_relative "lib/indented_print.rb"

def render_with(renderer)
  rng = Random.new(42)
  root_node = Node.new("Forum", [
    Node.new("Header"),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
    Node.new("Thread", [
      Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
      Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
      Node.new("Thread", [
        Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
        Node.new("Thread", [
          Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
          Node.new("Thread", Node.gen_n(rng.rand(120..210), "Post")),
        ]),
      ])
    ]),
    Node.new("Footer"),
  ])

  warn "== #{renderer}:"
  
  cache = CacheStore.new

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== First render (cold cache) required #{r} roundtrips"

  # Evict some keys
  cache.evict_matching(/^Forum/)
  cache.evict_ratio(0.5, random: rng)

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== Second render (half of keys evicted) required #{r} roundtrips"

  cache.evict_matching(/^Forum/)

  r = cache.measure {
    renderer.node_to_fragments(root_node, cache)
  }
  warn "== Third render (no eviction) required #{r} roundtrips"
  warn "\n"
end

# render_with(DepthFirstRenderer.new)
# render_with(BatchedDepthFirstRenderer.new)
render_with(BreadthFirstRenderer.new)
