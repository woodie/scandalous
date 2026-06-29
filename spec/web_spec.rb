ENV["APP_ENV"] = "test"

require "spec_helper"
require_relative "../web"

RSpec.describe WebApp do
  let(:file) { "#{Time.now.to_i}.pdf" }

  def app
    WebApp
  end

  context "with no files" do
    before { FileUtils.rm_rf(Dir.glob(File.join(ScanFiles::SCAN_FOLDER, "*.pdf"))) }

    describe "listing" do
      it "no files found" do
        get "/"
        expect(last_response).to be_ok
        expect(last_response.body).to have_tag("h2", text: "Available Scans")
        expect(last_response.body).to have_tag("p", text: "No files found in the directory.")
      end
    end

    describe "download missing file" do
      it "responds with 404" do
        get "/download/#{file}"
        expect(last_response).not_to be_ok
        expect(last_response.status).to eq(404)
      end
    end

    describe "files.json" do
      it "returns an empty list" do
        get "/files.json"
        expect(last_response).to be_ok
        expect(last_response.content_type).to eq("application/json")
        expect(JSON.parse(last_response.body)).to eq([])
      end
    end
  end

  context "with a file" do
    before { File.write(File.join(ScanFiles::SCAN_FOLDER, file), :content) }

    describe "listing" do
      it "file description" do
        get "/"
        expect(last_response).to be_ok
        expect(last_response.body).to have_tag("h2", text: "Available Scans")
        expect(last_response.body).to have_tag("a", href: "/download/#{file}")
        expect(last_response.body).to have_tag("a", text: "📄 7 Bytes")
        expect(last_response.body).to have_tag("span", text: "less than a minute ago")
      end
    end

    describe "download actual file" do
      it "responds with 200" do
        get "/download/#{file}"
        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
      end
    end

    describe "files.json" do
      it "serves ScanFiles.scans_json as JSON" do
        get "/files.json"
        expect(last_response).to be_ok
        expect(last_response.content_type).to eq("application/json")
        expect(JSON.parse(last_response.body)).to eq(JSON.parse(ScanFiles.scans_json.to_json))
      end
    end
  end
end

__END__

WebApp
  with no files
    listing
      no files found
    download missing file
      responds with 404
    files.json
      returns an empty list
  with a file
    listing
      file description
    download actual file
      responds with 200
    files.json
      serves ScanFiles.scans_json as JSON
