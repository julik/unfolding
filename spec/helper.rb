require "rspec"
require_relative "../renderer"
require_relative "shared_renderer_beavior"

RSpec::Matchers.matcher :hash_including_only do |*keys|
  match do |actual_hash|
    Set.new(actual_hash.keys) == Set.new(keys)
  end
end

RSpec::Matchers.matcher :be_same_set do |*ref_items|
  match do |actual_items|
    Set.new(actual_items) == Set.new(ref_items)
  end
  diffable
end
