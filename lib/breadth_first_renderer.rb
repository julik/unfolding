require "set"

class BreadthFirstRenderer
  class Hydrator
    def hydrate(tree_of_keys_and_nils, using_cache_store)
      # Converts a tree of [nil, "k1", ["k2", nil]] to ["k1", "k2"]
      cache_keys = collect_keys(tree_of_keys_and_nils)
      # Retrieves cached data for ["k1", "k2"], which will be ["data1", nil] (nil if cache miss)
      cached_values = using_cache_store.read_multi(cache_keys)

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

  # It is very easy to make a mistake with state transitions, so a good idea
  # is to have a state machine which answers to methods and also prevents incorrect
  # state transitions altogether
  class RenderNodeState
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

  class RenderNode
    def initialize(node)
      @state = RenderNodeState.new
      @node = node
      @children = nil
      @fragments = []
    end

    def collect_dependent_cache_keys
      if @state.folded?
        debug "Returning cache key for self"
        @node.cache_key
      elsif @state.unfolding?
        debug "Still unfolding, returning dependent child keys"
        @children.map(&:collect_dependent_cache_keys)
      end
    end

    def pushdown_values_from_cache(value_from_cache)
      if @state.done?
        debug "Received cache values but already done"
      elsif @state.folded?
        if value_from_cache
          debug "Сache hit (received #{value_from_cache.inspect})"
          @fragments = value_from_cache
          @state.advance_to(:done)
        else
          debug "Сache miss (received #{value_from_cache.inspect})"
          # There was no cache for ourselves, so we need to "unfold" our children
          # to see whether those are cached instead
          @state.advance_to(:unfolding)
          @children = @node.children.map { |n| self.class.new(n) }
        end
      elsif @state.unfolding?
        debug "Received cache values for children: #{value_from_cache}"

        @children.zip(value_from_cache).each do |child_render_node, value_for_child|
          child_render_node.pushdown_values_from_cache(value_for_child)
        end
        return unless @children.all?(&:done?)

        debug "All children are done (or leaf node), rendering"
        render!
      else
        raise "Should not receive pushdown_values_from_cache() while #{@state}"
      end
    end

    def collect_rendered_caches(into_hash)
      if @state.done?
        debug "Collecting cache for self"
        into_hash[@node.cache_key] = @fragments.dup
      elsif @state.unfolding?
        debug "Collecting child caches"
        @children.map do |child_render_node|
          child_render_node.collect_rendered_caches(into_hash)
        end
      end
      # otherwise - do nothing
    end

    def render!
      @state.advance_to(:rendering)
      @fragments = if @children.any?
        [
          "<#{@node.name} id=#{@node.id}>",
          @children.map(&:fragments),
          "</#{@node.name}>"
        ]
      else
        ["<#{@node.name} id=#{@node.id} />"]
      end
      @state.advance_to(:done)
    end

    def fragments
      raise "Fragments not available yet (still #{@state})" unless @state.done?
      @fragments
    end

    def done?
      @state.done?
    end

    def to_s
      "RN(#{@node.cache_key} #{@state}):>"
    end

    def debug(str)
      # warn "#{self}: #{str}"
    end
  end

  def node_to_fragments(node, cache_store)
    root_node = RenderNode.new(node)
    hydrator = Hydrator.new

    loop do |n|
      tree_of_keys = root_node.collect_dependent_cache_keys
      tree_of_values = hydrator.hydrate(tree_of_keys, cache_store)
      root_node.pushdown_values_from_cache(tree_of_values)

      keys_to_values_for_cache = {}
      root_node.collect_rendered_caches(keys_to_values_for_cache)

      cache_store.write_multi(keys_to_values_for_cache) if keys_to_values_for_cache.any?

      return root_node.fragments if root_node.done?
    end
  end
end
