require "spec_helper"
require_relative "../lib/scan_files"

RSpec.describe ScanFiles do
  describe "#cleanup" do
    subject { ScanFiles.cleanup }

    context "with no files" do
      let(:files) { [] }

      it "nothing to do" do
        expect(Dir).to receive(:glob).and_return(files)
        expect(File).not_to receive(:file?)
        subject
      end
    end

    context "with one file" do
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

    context "with one attachments" do
      let(:attachments) { [double({content_type: "application/pdf"})] }

      it "detache PDF files" do
        expect(File).to receive(:open)
        subject
      end
    end
  end
end
