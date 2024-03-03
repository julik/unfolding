require_relative "lib/node.rb"
require_relative "lib/cache_store.rb"
require_relative "lib/depth_first_renderer.rb"
require_relative "lib/breadth_first_renderer.rb"
require_relative "lib/indented_print.rb"


def render_with(renderer)
  cache = CacheStore.new
  topic = Node.new("Topic1", [
    Node.new("Post1", [Node.new("Avatar1")]),
    Node.new("Post2", [Node.new("Avatar2"), Node.new("Avatar4")]),
    Node.new("Post3", [Node.new("Avatar3")])
  ])

  warn "== First render (cold cache)"
  indented_print(renderer.node_to_fragments(topic, cache))

  # Note that since Ruby Hashes are now insertion-ordered, we will
  # see keys in the order they got written to the cache. This reflects the tree
  # traversal order.
  warn cache.keys.inspect
  cache.delete("Post1")

  warn "\n== Second render (warm cache)"
  indented_print(renderer.node_to_fragments(topic, cache))
end

#warn "= Depth-first"
#render_with(DepthFirstRenderer.new)

warn "= Breadth-first"
render_with(BreadthFirstRenderer.new)

