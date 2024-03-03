require "set"

class BreadthFirstRenderer
  class CachedFuture < Struct.new(:key, :requesting_fiber, :value)
    def accept_value_from_cache(value_or_nil)
      self.value = value_or_nil
      requesting_fiber.resume if requesting_fiber
    end
  end

  class CacheExchanger
    def initialize(store)
      @store = store
      @resolved = []
      @pending = []
    end

    def request(requesting_fiber, key)
      CachedFuture.new(key, requesting_fiber, nil).tap do |fut|
        @pending << fut
      end
    end

    def store(k, v)
      @store.set(k, v)
    end

    def resolve
      keys_to_fetch = @pending.map(&:key)
      values_or_nils = @store.get_multi(keys_to_fetch)
      @pending.zip(values_or_nils).each do |(fut, value_from_cache)|
        fut.accept_value_from_cache(value_from_cache)
      end
      @resolved, @pending = @pending, []
    end
  end

  class Stepper
    def initialize(node, children)
      @node = node
      @children = children
    end

    def render(using_cache_exchanger)
      # Request the value from the cache. This actually does a Fiber.yield
      # and suspends the call until the fut is returned and it is either
      # resolved (fetched from cache) or not resolved (cache miss)
      fut = using_cache_exchanger.request(nil, @node.id)
      return fut.value if fut.value # Will be the fragments

      # At this stage we must go in and process stuff breadth-first
      fragments = []
      fragments << "<#{@node.id}>"
      fragments += @children.map do |c|
        c.render(using_cache_exchanger)
      end
      fragments << "</#{@node.id}>"
      using_cache_exchanger.store(@node.id, fragments)

      fragments
    end
  end

  def node_to_fragments(node, cache_store)
    stepper = wrap(node)
    ex = CacheExchanger.new(cache_store)
    stepper.render(ex)
  end

  def wrap(parent_node)
    child_steppers = parent_node.children.map {|child_node| wrap(child_node) }
    Stepper.new(parent_node, child_steppers)
  end
end
