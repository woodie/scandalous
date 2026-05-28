require "spec_helper"
require_relative "../lib/scan_files"

RSpec.describe ScanFiles do
  describe "#interface" do
    let(:ext_host) { ENV["EXT_HOST"] }
    let(:actual) { Net::HTTP.get_response(URI("https://api.ipify.org"))&.body }

    subject { ScanFiles.interface }

    it "indicates correct settings" do
      expect(subject).to eq("✅ #{ext_host} = #{actual}")
    end

    context "with stale configuration" do
      before { allow(Resolv).to receive(:getaddress).with(ext_host).and_return("0.0.0.0") }

      it "indicates incorrect settings" do
        expect(subject).to eq("⛔ #{ext_host} ≠ #{actual}")
      end
    end
  end

  describe "#listing" do
    subject { ScanFiles.listing }

    context "with path to file" do
      let(:time) { Time.now }
      let(:size) { 11111111 }
      let(:name) { "1234567890.pdf" }
      let(:list) { [{time: time, name: name, size: size}] }

      it "returns a payload" do
        allow(Dir).to receive(:glob).and_return([".some/path/#{name}"])
        expect(File).to receive(:mtime).and_return(time)
        expect(File).to receive(:size).and_return(size)
        expect(subject).to eq(list)
      end
    end
  end

  describe "#cleanup" do
    subject { ScanFiles.cleanup }

    context "with a file" do
      let(:files) { ["1234567890.pdf"] }

      before(:each) do
        allow(Dir).to receive(:glob).and_return(files)
        expect(File).to receive(:file?).with(files.first).and_return(true)
        expect(File).to receive(:mtime).with(files.first).and_return(time)
      end

      context "created right now" do
        let(:time) { Time.now }

        it "keeps the file" do
          expect(File).not_to receive(:delete)
          subject
        end
      end

      context "created yesterday" do
        let(:time) { Time.now - ScanFiles::ONE_DAY_AGO.to_i }

        it "deletes the file" do
          expect(File).to receive(:delete).with(files.first).and_return(true)
          subject
        end
      end
    end
  end

  describe "#detach" do
    subject { ScanFiles.detach(attachments) }

    context "with no attachments" do
      let(:attachments) { [] }

      it "nothing to do" do
        expect(File).not_to receive(:open)
        subject
      end
    end

    context "with one attachment" do
      let(:attachments) { [double({content_type: "application/pdf"})] }

      it "detaches file" do
        expect(File).to receive(:open)
        subject
      end

      context "when write fails" do
        before { allow(File).to receive(:open).and_raise(IOError) }

        it "catches the error" do
          subject
        end
      end
    end
  end
end

__END__

ScanFiles
  #interface
    indicates correct settings
    with stale configuration
      indicates incorrect settings
  #listing
    with path to file
      returns a payload
  #cleanup
    with a file
      created right now
        keeps the file
      created yesterday
        deletes the file
  #detach
    with no attachments
      nothing to do
    with one attachment
      detaches file
      when write fails
        catches the error
