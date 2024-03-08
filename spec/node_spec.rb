require_relative "helper"

RSpec.describe Node do
  it "has a name and provides proper cache key" do
    node = Node.new("Foo")
    expect(node.id).not_to be_nil
    expect(node.cache_key).to be_kind_of(String)
  end
end