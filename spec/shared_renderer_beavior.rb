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
end
