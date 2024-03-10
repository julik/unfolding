RSpec.shared_examples "a renderer" do
  let(:root_node) do
    b = Node::Builder.new
    b.node("Root") do
      b.node("Child")
      b.node("Child") do
        b.node("Grandchild")
        b.node("Grandchild") do
          b.node("Grandgrandchild")
        end
        b.node("Grandchild")
      end
    end
  end

  it "should output the same content on repeated renders" do
    cache = CacheStore.new
    render_outputs = 20.times.map do
      subject.node_to_fragments(root_node, cache)
    end

    render_outputs.each_cons(2) do |prev_render, next_render|
      expect(next_render).to eq(prev_render)
    end
  end

  it "should output the same fragments as a NaiveRenderer" do
    next if subject.is_a?(NaiveRenderer)

    ref_output = NaiveRenderer.new.node_to_fragments(root_node, _cache_store = nil)

    output = subject.node_to_fragments(root_node, CacheStore.new)
    expect(output).to eq(ref_output)
  end

  before :each do
    Node::ID_DISPENCER = (0..).each
  end

  it "renders a single node" do
    node = Node.new("Root")
    fragments = subject.node_to_fragments(node, CacheStore.new)
    expect(fragments).to eq(["<Root id=0 />"])
  end

  it "renders a tree of two nodes" do
    root_node = Node.build("Root") do |b|
      b.node("Child")
    end

    fragments = subject.node_to_fragments(root_node, CacheStore.new)
    expect(fragments).to eq(["<Root id=1>", [["<Child id=0 />"]], "</Root>"])
  end

  it "renders a tree of three nodes" do
    root_node = Node.build("Root") do |b|
      b.node("Child") do
        b.node("Grandchild")
      end
    end

    fragments = subject.node_to_fragments(root_node, CacheStore.new)
    expect(fragments).to eq(["<Root id=2>", [["<Child id=1>", [["<Grandchild id=0 />"]], "</Child>"]], "</Root>"])
  end

  it "renders a tree of four nodes" do
    root_node = Node.build("Root") do |b|
      b.node("Child") do
        b.node("Grandchild") do
          b.node("Grandgrandchild")
        end
      end
    end

    fragments = subject.node_to_fragments(root_node, CacheStore.new)
    expect(fragments).to eq(["<Root id=3>", [["<Child id=2>", [["<Grandchild id=1>", [["<Grandgrandchild id=0 />"]], "</Grandchild>"]], "</Child>"]], "</Root>"])
  end
end
