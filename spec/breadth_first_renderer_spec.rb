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

  it "performs one read_multi and one write_multi per level of the tree" do
    root_node = Node.build("Root") do |b|
      b.node("Parent") do
        3.times { b.node("Child") }
      end
      b.node("AnotherParent") do
        3.times { b.node("Child") }
      end
    end

    store = CacheStore.new
    multi_read_args = [
      ["Root-8"],
      ["Parent-3", "AnotherParent-7"],
      ["Child-0", "Child-1", "Child-2", "Child-4", "Child-5", "Child-6"],
    ]
    multi_read_args.each do |args|
      expect(store).to receive(:read_multi).with(args).and_call_original
    end
    multi_write_args = [
      hash_including("Child-0", "Child-1", "Child-2", "Parent-3", "Child-4", "Child-5", "Child-6", "AnotherParent-7", "Root-8")
    ]
    multi_write_args.each do |args|
      expect(store).to receive(:write_multi).with(args).and_call_original
    end

    subject.node_to_fragments(root_node, store)

    # Zap "Root" and the first "Parent". These nodes will be re-written into the cache
    store.evict_matching("Root-8", "Parent-3")

    multi_read_args = [
      ["Root-8"],
      ["Parent-3", "AnotherParent-7"],
      ["Child-0", "Child-1", "Child-2"]
    ]
    multi_read_args.each do |args|
      expect(store).to receive(:read_multi).with(args).and_call_original
    end
    multi_write_args = [
      hash_including_only("Parent-3", "Root-8")
    ]
    multi_write_args.each do |args|
      expect(store).to receive(:write_multi).with(args).and_call_original
    end

    subject.node_to_fragments(root_node, store)
  end
end
