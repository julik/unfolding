require "set"

class BreadthFirstRenderer
  # It is very easy to make a mistake with state transitions, so a good idea
  # is to have a state machine which answers to methods and also prevents incorrect
  # state transitions altogether
  class RenderingState
    PERMITTED_TRANSITIONS = [
      [:folded, :unfolding],
      [:folded, :done],
      [:unfolding, :rendering],
      [:rendering, :done]
    ]

    def initialize
      @state = :folded
    end

    def advance_or_stay_in(state)
      return if @state == state
      advance_to(state)
    end

    def advance_to(state)
      raise "Cannot transition #{@state} -> #{state}" unless PERMITTED_TRANSITIONS.include?([@state, state])
      @state = state
    end

    def to_s
      "S(#{@state.inspect})"
    end

    states = PERMITTED_TRANSITIONS.flatten.uniq
    states.each do |state|
      define_method(:"#{state}?") { @state == state }
    end
  end

  class CacheState
    PERMITTED_TRANSITIONS = [
      [:in_progress, :rendered_from_cache],
      [:in_progress, :rendered_fresh],
      [:rendered_fresh, :cache_written],
    ]

    def initialize
      @state = :in_progress
    end

    def advance_or_stay_in(state)
      return if @state == state
      advance_to(state)
    end

    def advance_to(state)
      raise "Cannot transition #{@state} -> #{state}" unless PERMITTED_TRANSITIONS.include?([@state, state])
      @state = state
    end

    def to_s
      "S(#{@state.inspect})"
    end

    states = PERMITTED_TRANSITIONS.flatten.uniq
    states.each do |state|
      define_method(:"#{state}?") { @state == state }
    end
  end

  class RenderNode
    def initialize(node)
      @rendering_state = RenderingState.new
      @cache_state = CacheState.new
      @node = node
      @children = nil
      @fragments = []
    end

    def collect_dependent_cache_keys
      if @rendering_state.folded?
        @node.cache_key
      elsif @rendering_state.unfolding?
        @children.map(&:collect_dependent_cache_keys)
      end
    end

    def pushdown_values_from_cache(value_from_cache)
      if @rendering_state.folded? && value_from_cache
        @fragments = value_from_cache
        @rendering_state.advance_to(:done)
        @cache_state.advance_to(:rendered_from_cache)
      elsif @rendering_state.folded?
        # There was no cache for ourselves, so we need to "unfold" our children
        # to see whether those are cached instead
        @rendering_state.advance_to(:unfolding)
        @children = @node.children.map { |n| self.class.new(n) }
      elsif @rendering_state.unfolding?
        @children.zip(value_from_cache).each do |child_render_node, value_for_child|
          child_render_node.pushdown_values_from_cache(value_for_child)
        end
        # This will allow children to deliver their cache keys into collect_rendered_caches
        # at this iteration of the loop. This can be optimized further by calling `render!`
        # immediately here
        @rendering_state.advance_to(:rendering) if @children.all?(&:done?)
      elsif @rendering_state.rendering?
        render!
      end
    end

    def collect_rendered_caches(into_hash)
      (@children || []).each do |child_render_node|
        child_render_node.collect_rendered_caches(into_hash)
      end

      if @rendering_state.done? && @cache_state.rendered_fresh?
        @cache_state.advance_to(:cache_written)
        into_hash[@node.cache_key] = @fragments
      end
    end

    def render!
      @fragments = if @children.any?
        [
          "<#{@node.name} id=#{@node.id}>",
          @children.map(&:fragments),
          "</#{@node.name}>"
        ]
      else
        ["<#{@node.name} id=#{@node.id} />"]
      end
      @cache_state.advance_to(:rendered_fresh)
      @rendering_state.advance_to(:done)
    end

    def fragments
      raise "Fragments not available yet (still #{@rendering_state})" unless @rendering_state.done?
      @fragments
    end

    def done?
      @rendering_state.done?
    end

    def to_s
      "RN(#{@node.cache_key} #{@rendering_state}):>"
    end
  end

  def node_to_fragments(node, cache_store)
    root_node = RenderNode.new(node)

    loop do |n|
      tree_of_keys = root_node.collect_dependent_cache_keys
      tree_of_values = hydrate(tree_of_keys, cache_store)
      root_node.pushdown_values_from_cache(tree_of_values)

      keys_to_values_for_cache = {}
      root_node.collect_rendered_caches(keys_to_values_for_cache)

      cache_store.write_multi(keys_to_values_for_cache) if keys_to_values_for_cache.any?

      return root_node.fragments if root_node.done?
    end
  end

  def hydrate(tree_of_keys_and_nils, using_cache_store)
    # Converts a tree of [nil, "k1", ["k2", nil]] to ["k1", "k2"]
    cache_keys_to_read = collect_keys(tree_of_keys_and_nils)

    # A cache store likely won't like an empty array of keys
    return with_replacements_from(tree_of_keys_and_nils, []) if cache_keys_to_read.empty?

    # Retrieves cached data for ["k1", "k2"], which will be ["data1", nil] (nil if cache miss)
    cached_values = using_cache_store.read_multi(cache_keys_to_read)

    # Merges ["data1", nil] into [nil, "k1", ["k2", nil]] to return a tree of [nil, "data1", [nil, nil]]
    with_replacements_from(tree_of_keys_and_nils, cached_values)
  end

  private

  def collect_keys(branch, collect_into = [])
    case branch
    when Array
      branch.map { |leaf| collect_keys(leaf, collect_into) }
    when NilClass
      # pass
    else
      collect_into << branch
    end
    collect_into
  end

  def with_replacements_from(branch, from_flat_array)
    case branch
    when Array
      branch.map { |leaf| with_replacements_from(leaf, from_flat_array) }
    when NilClass
      nil
    else
      from_flat_array.shift
    end
  end
end
