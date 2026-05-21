require "spec_helper"
require_relative "../lib/formatter"

RSpec.describe Formatter do
  let(:time) { "less than a minute" }
  let(:size) { "97.7 KB" }

  describe ".listing" do
    subject { Formatter.new.listing(path) }

    context "with path to file" do
      let(:path) { "/path/to/files" }
      let(:file) { "1234567890.pdf" }
      let(:list) { [{time: time, name: file, size: size}] }

      it "returns a payload" do
        expect(Dir).to receive(:entries).with(path).and_return([file])
        expect(File).to receive(:mtime).and_return(Time.now)
        expect(File).to receive(:size).and_return(99999)
        expect(subject).to eq(list)
      end
    end
  end

  describe ".time_ago" do
    subject { Formatter.new.time_ago(whence) }

    context "when just now" do
      let(:whence) { Time.now }

      it "describes when" do
        expect(subject).to eq(time)
      end
    end
  end

  describe ".to_human" do
    subject { Formatter.new.to_human(bytes) }

    context "with some bytes" do
      let(:bytes) { 99999 }

      it "formats nicely" do
        expect(subject).to eq(size)
      end
    end
  end
end
