RSpec.shared_examples "a renderer" do
  let(:root_node) do
    b = Node::Builder.new
    b.node("Root") do
      b.node("Child")
      b.node("Child") do
        b.node("Grandchild")
        b.node("Grandchild")
        b.node("Grandchild")
      end
    end
  end

  it "should output the same content on repeated renders" do
    cache = CacheStore.new
    render_outputs = 4.times.map do
      subject.node_to_fragments(root_node, cache)
    end

    render_outputs.each_cons(2) do |prev_render, next_render|
      expect(next_render).to eq(prev_render)
    end
  end

  it "provides same output as DepthFirstRenderer" do
    skip("No point testing DepthFirstRenderer against itself") if subject.is_a?(DepthFirstRenderer)

    cache1 = CacheStore.new
    ref_output = DepthFirstRenderer.new.node_to_fragments(root_node, cache1)
    
    cache2 = CacheStore.new
    output = subject.node_to_fragments(root_node, cache2)

    expect(output).to eq(ref_output)
  end
end
