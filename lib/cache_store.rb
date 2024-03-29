class CacheStore
  attr_reader :roundtrips

  def initialize(hashmap = nil)
    @c = hashmap.to_h
    @roundtrips = 0
  end

  def read(k)
    @roundtrips += 1
    @c[k]
  end

  def read_multi(keys)
    @roundtrips += 1
    keys.map { |k| @c[k] }
  end

  def write(k, v)
    @roundtrips += 1
    @c[k] = v
  end

  def write_multi(keys_to_values)
    @roundtrips += 1
    keys_to_values.each_pair do |k, v|
      @c[k] = v
    end
  end

  def evict_ratio(of_total_keys, random: Random.new)
    n_keys = (@c.length * of_total_keys).floor
    @c.keys.sample(n_keys, random: random).each { |k| @c.delete(k) }
  end

  def evict_matching(*patterns_or_strings)
    patterns_or_strings.each do |pattern|
      @c.keys.grep(pattern).each { |k| @c.delete(k) }
    end
  end

  def measure
    before = @roundtrips
    yield
    @roundtrips - before
  end

  # This is not used by the renderers but by the test harness,
  # to selectively wipe keys
  def delete(key)
    @c.delete(key)
  end

  def key_count
    @c.length
  end

  def inspect
    "<CacheStore with #{@c.length} keys>"
  end

  def keys
    @c.keys
  end

  alias_method :to_s, :inspect
end
