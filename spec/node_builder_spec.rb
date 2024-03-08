require_relative "helper"

RSpec.describe Node::Builder do
  it "builds a tree root" do
    b = Node::Builder.new
    root_node = b.node("Root")
    expect(root_node.name).to eq("Root")
    expect(root_node.children).to be_empty
  end

  it "builds a tree" do
    b = Node::Builder.new
    root_node = b.node("Root") do
      b.node("Branch")
      b.node("Branch") do
        b.node("Leaf")
        b.node("Leaf")
      end
    end

    expect(root_node.name).to eq("Root")
    expect(root_node.children).not_to be_empty
    expect(root_node.children[0].name).to eq("Branch")
    expect(root_node.children[1].name).to eq("Branch")

    first_branch, second_branch = root_node.children
    expect(first_branch.children).to be_empty
    expect(second_branch.children).not_to be_empty

    first_leaf, second_leaf = second_branch.children
    expect(first_leaf.name).to eq("Leaf")
    expect(second_leaf.name).to eq("Leaf")
  end
end
