require "set"

class BreadthFirstRenderer
  class Hydrator
    def hydrate(tree_of_keys_and_nils, using_cache_store)
      # Converts a tree of [nil, "k1", ["k2", nil]] to ["k1", "k2"]
      cache_keys = collect_keys(tree_of_keys_and_nils)
      # Retrieves cached data for ["k1", "k2"], which will be ["data1", nil] (nil if cache miss)
      warn cache_keys.inspect
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

  class RenderNode
    WAITING_FOR_CACHE = :opaque
    UNFOLDING_CHILDREN = :unfolding
    RENDERING = :rendering
    DONE = :done

    def initialize(node)
      @node = node
      @phase = WAITING_FOR_CACHE
      @children = nil
      @fragments = []
      @rendered_from_cache = false
    end

    def collect_dependent_cache_keys
      case @phase
      when WAITING_FOR_CACHE
        debug "#{self} is returning its cache key"
        @node.cache_key
      when UNFOLDING_CHILDREN
        debug "#{self} is unfolding children and will push up child keys"
        @children.map(&:collect_dependent_cache_keys)
      when DONE
        nil # Request a "hole" which will not be fetched from the cache
      end
    end

    def pushdown_values_from_cache(value_for_self_or_children)
      case @phase
      when WAITING_FOR_CACHE
        if value_for_self_or_children
          debug "#{self} had a cache hit"
          @fragments = value_for_self_or_children
          @phase = DONE
          @rendered_from_cache = true
        else
          debug "#{self} had a cache miss, will start unfolding children"
          # We need to "unfold" the child nodes, since we are going to be rendering
          @phase = UNFOLDING_CHILDREN
          @children = @node.children.map {|n| self.class.new(n) }
        end
      when UNFOLDING_CHILDREN
        @children.zip(value_for_self_or_children).each do |child_render_node, value_for_child|
          child_render_node.pushdown_values_from_cache(value_for_child)
        end
        # If all the children have received their values, we can render
        render! if @children.all?(&:done?)
        @phase = DONE
      when DONE
        nil # Nothing to do
      end
    end

    def collect_rendered_caches(into = {}) #-> Hash
      if done? && @node.cache_key && !@rendered_from_cache
        into[@node.cache_key] = @fragments
      else
        (@children || []).map {|c| c.collect_rendered_caches(into) }
      end
      into
    end

    def render!
      debug "#{self} is rendering"
      @fragments = if @children.any?
        [
          "<#{@node.id}>",
          @children.map(&:fragments),
          "</#{@node.id}>"
        ]
      else
        ["<#{@node.id} />"]
      end
    end

    def fragments
      raise "Fragments requested, but #{self} is in still in the #{@phase} phase" unless @phase == DONE
      @fragments
    end

    def done?
      @phase == DONE
    end

    def to_s
      "RN(#{@node.cache_key}):#{@phase}>"
    end

    def debug(str)
      warn str
    end
  end

  def node_to_fragments(node, cache_store)
    root_node = RenderNode.new(node)
    hydrator = Hydrator.new

    loop do |n|
      tree_of_keys = root_node.collect_dependent_cache_keys
      tree_of_values = hydrator.hydrate(tree_of_keys, cache_store)
      root_node.pushdown_values_from_cache(tree_of_values)

      keys_to_values = root_node.collect_rendered_caches
      warn keys_to_values.inspect
      cache_store.write_multi(keys_to_values) if keys_to_values.any?

      break root_node.fragments if root_node.done?
    end
  end
end
