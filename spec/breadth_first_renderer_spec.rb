require_relative "helper"

RSpec.describe BreadthFirstRenderer do
  it_should_behave_like "a renderer"

  it "is able to hydrate trees from cache" do
    empty_cache = CacheStore.new

    expect(subject.hydrate(nil, empty_cache)).to eq(nil)
    expect(subject.hydrate([nil], empty_cache)).to eq([nil])
    expect(subject.hydrate([[nil], [nil]], empty_cache)).to eq([[nil], [nil]])
    expect(subject.hydrate(["foo", nil], empty_cache)).to eq([nil, nil])
    expect(subject.hydrate([["foo", nil]], empty_cache)).to eq([[nil, nil]])

    cache = CacheStore.new({"foo" => 123, "bar" => 456})
    expect(subject.hydrate(nil, cache)).to eq(nil)
    expect(subject.hydrate("foo", cache)).to eq(123)
    expect(subject.hydrate(["foo", "bar", ["baz"]], cache)).to eq([123, 456, [nil]])
  end
end
