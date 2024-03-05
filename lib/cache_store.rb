class CacheStore
  def initialize
    @c = {}
  end

  def get(k)
    @c[k]
  end

  def read_multi(keys)
    keys.map {|k| @c[k] }
  end

  def set(k, v)
    @c[k] = v
  end

  def clear
    @c.clear
  end

  def keys
    @c.keys
  end

  def delete(key)
    @c.delete(key)
  end
end
