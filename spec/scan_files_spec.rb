require "spec_helper"
require "mail"
require "tmpdir"
require "base64"
require_relative "../lib/scan_files"

RSpec.describe ScanFiles do
  let(:plain_message) do
    "From: sender@example.com\r\n" \
    "Content-Type: text/plain\r\n" \
    "\r\nHello world"
  end

  let(:inline_message) do
    "From: sender@example.com\r\n" \
    "Content-Type: multipart/mixed; boundary=boundary\r\n" \
    "\r\n--boundary\r\n" \
    "Content-Type: text/plain\r\n" \
    "\r\njust body text\r\n" \
    "--boundary--\r\n"
  end

  let(:multipart_message) do
    "From: sender@example.com\r\n" \
    "Content-Type: multipart/mixed; boundary=boundary\r\n" \
    "\r\n--boundary\r\n" \
    "Content-Disposition: attachment; filename=\"test.txt\"\r\n" \
    "\r\nfile content\r\n" \
    "--boundary--\r\n"
  end

  let(:base64_pdf_message) do
    "From: sender@example.com\r\n" \
    "Content-Type: multipart/mixed; boundary=boundary\r\n" \
    "\r\n--boundary\r\n" \
    "Content-Type: application/pdf\r\n" \
    "Content-Disposition: attachment; filename=\"test.pdf\"\r\n" \
    "Content-Transfer-Encoding: base64\r\n" \
    "\r\n#{Base64.strict_encode64("fake pdf content")}\r\n" \
    "--boundary--\r\n"
  end

  around do |example|
    Dir.mktmpdir do |dir|
      original_scan_folder = ScanFiles.scan_folder
      ScanFiles.scan_folder = dir
      example.run
      ScanFiles.scan_folder = original_scan_folder
    end
  end

  describe "#listing" do
    subject { ScanFiles.listing }

    context "with no files" do
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "with a file on disk" do
      let(:name) { "1234567890.pdf" }
      let(:path) { File.join(ScanFiles.scan_folder, name) }

      before { File.write(path, "x" * 42) }

      it "returns its name, mtime, and size" do
        expect(subject).to eq([{name: name, time: File.mtime(path), size: 42}])
      end
    end
  end

  describe "#scans_json" do
    subject { ScanFiles.scans_json }

    context "with no files" do
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "with a file on disk" do
      let(:name) { "1234567890.pdf" }
      let(:path) { File.join(ScanFiles.scan_folder, name) }

      before { File.write(path, "x" * 42) }

      it "returns name/size/time/path" do
        expect(subject).to eq([
          {name: name, size: 42, time: File.mtime(path).iso8601, path: "/download/#{name}"}
        ])
      end
    end
  end

  describe "#cleanup" do
    let(:pdf) { File.join(ScanFiles.scan_folder, "1234567890.pdf") }

    before { File.write(pdf, "data") }

    context "when the file is recent" do
      it "keeps it" do
        ScanFiles.cleanup
        expect(File.exist?(pdf)).to be true
      end
    end

    context "when the file is older than a day" do
      before do
        old = Time.now - (25 * 60 * 60)
        File.utime(old, old, pdf)
      end

      it "deletes it" do
        ScanFiles.cleanup
        expect(File.exist?(pdf)).to be false
      end
    end

    context "with a non-PDF file present" do
      let(:other) { File.join(ScanFiles.scan_folder, "notes.txt") }

      before do
        File.write(other, "data")
        old = Time.now - (25 * 60 * 60)
        File.utime(old, old, other)
      end

      it "leaves it alone regardless of age -- cleanup only globs *.pdf" do
        ScanFiles.cleanup
        expect(File.exist?(other)).to be true
      end
    end
  end

  describe "#detach" do
    subject { ScanFiles.detach(Mail.read_from_string(raw).attachments) }

    def saved_files
      Dir.glob(File.join(ScanFiles.scan_folder, "*"))
    end

    context "with a plain-text message (not multipart)" do
      let(:raw) { plain_message }

      it "saves no files" do
        subject
        expect(saved_files).to be_empty
      end
    end

    context "with a multipart message that has only an inline part" do
      let(:raw) { inline_message }

      it "saves no files" do
        subject
        expect(saved_files).to be_empty
      end
    end

    context "with a non-PDF attachment" do
      let(:raw) { multipart_message }

      it "skips it" do
        subject
        expect(saved_files).to be_empty
      end
    end

    context "with a base64-encoded PDF attachment" do
      let(:raw) { base64_pdf_message }

      it "saves one file" do
        subject
        expect(saved_files.length).to eq(1)
      end

      it "decodes the base64 content correctly" do
        subject
        expect(File.read(saved_files.first)).to eq("fake pdf content")
      end

      it "names the file with a .pdf extension" do
        subject
        expect(saved_files.first).to end_with(".pdf")
      end
    end

    context "when the destination directory doesn't exist" do
      let(:raw) { base64_pdf_message }

      before { ScanFiles.scan_folder = File.join(ScanFiles.scan_folder, "missing") }

      it "rescues the error instead of raising" do
        expect { subject }.not_to raise_error
      end

      it "saves no files" do
        subject
        expect(saved_files).to be_empty
      end
    end
  end
end
