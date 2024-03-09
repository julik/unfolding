require_relative "helper"

RSpec.describe CacheStore do
  it "supports write and read" do
    expect(subject.read("foo")).to be_nil
    expect(subject.write("foo", 123)).to eq(123)
    expect(subject.read("foo")).to eq(123)
  end

  it "supports write_multi and read_multi" do
    expect(subject.read_multi(["foo", "bar"])).to eq([nil, nil])
    subject.write("foo", 123)
    expect(subject.read_multi(["foo", "bar"])).to eq([123, nil])

    subject.write_multi({"foo" => 456, "bar" => "x"})
    expect(subject.read_multi(["foo", "bar"])).to eq([456, "x"])
  end

  it "records the number of roundtrips" do
    t = subject.measure do
      subject.read("foo")
      subject.write("foo", "x")
    end

    expect(t).to eq(2)

    t = subject.measure do
      subject.read_multi(["foo", "bar"])
      subject.write_multi({"bar" => 123, "baz" => 456})
    end
    expect(t).to eq(2)
  end
end
