require "spec_helper"
require_relative "../lib/formatter"

RSpec.describe Formatter do
  describe ".listing" do
    subject { Formatter.new.listing(path) }

    context "with path to file" do
      let(:path) { "/path/to/files" }
      let(:file) { "1234567890.pdf" }
      let(:list) { [{date: "less than a minute", name: file, size: "9.76 KB"}] }

      it "returns a payload" do
        expect(Dir).to receive(:entries).with(path).and_return([file])
        expect(File).to receive(:mtime).and_return(Time.now)      
        expect(File).to receive(:size).and_return(9999)      
        expect(subject).to eq(list)
      end 
    end 
  end 

  describe ".time_ago" do
    subject { Formatter.new.time_ago(time) }

    context "when just now" do
      let(:time) { Time.now}

      it "describes when" do
        expect(subject).to eq("less than a minute")
      end 
    end 
  end 

  describe ".to_human" do
    subject { Formatter.new.to_human(bytes) }

    context "with some bytes" do
      let(:bytes) { 9999 }

      it "formats nicely" do
        expect(subject).to eq("9.76 KB")
      end 
    end 
  end 
end 
