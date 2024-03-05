require "set"

class BreadthFirstRenderer
  class Hydrator
    def hydrate(tree_of_keys_and_nils, using_cache_store)
      cache_keys = collect_keys(tree_of_keys_and_nils)
      cached_values = using_cache_store.read_multi(cache_keys)
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
          @fragments = value_for_self_or_children
          @phase = DONE
        else
          debug "#{self} had cache miss, will start unfolding children"
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
      when DONE
        nil # Nothing to do
      end
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

      @phase = DONE
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
    end
  end

  def node_to_fragments(node, cache_store)
    root_node = RenderNode.new(node)
    hydrator = Hydrator.new

    loop do |n|
      warn "=== PASS #{n}"
      tree_of_keys = root_node.collect_dependent_cache_keys
      tree_of_values = hydrator.hydrate(tree_of_keys, cache_store)
      warn "Cache: #{tree_of_keys.inspect} -> #{tree_of_values.inspect}"
      root_node.pushdown_values_from_cache(tree_of_values)
      break root_node.fragments if root_node.done?
    end
  end
end
