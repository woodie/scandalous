ENV["APP_ENV"] = "test"

require "spec_helper"
require_relative "../web"

RSpec.describe WebApp do
  let(:file) { "#{Time.now.to_i}.pdf" }

  def app
    WebApp
  end

  context "with no files" do
    before { FileUtils.rm_rf(Dir.glob(File.join(ScanFiles.scan_folder, "*.pdf"))) }

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

    describe "delete missing file" do
      it "responds with 404" do
        delete "/download/#{file}"
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
    before { File.write(File.join(ScanFiles.scan_folder, file), :content) }

    describe "listing" do
      it "displays a file listing" do
        get "/"
        expect(last_response).to be_ok
        expect(last_response.body).to have_tag("h2", text: "Available Scans")
        expect(last_response.body).to have_tag("a", href: "/download/#{file}")
        expect(last_response.body).to have_tag("a", text: "📄 7 Bytes")
        expect(last_response.body).to have_tag("span", text: "less than a minute ago")
      end

      it "wires the delete confirm dialog with the full message" do
        get "/"
        expect(last_response.body).to have_tag(
          "button.delete",
          onclick: "deleteFile('#{file}', 'Delete this scan from less than a minute ago?')"
        )
      end
    end

    describe "download actual file" do
      it "responds with 200" do
        get "/download/#{file}"
        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
      end
    end

    describe "delete actual file" do
      it "responds with 204 and removes the file" do
        delete "/download/#{file}"
        expect(last_response.status).to eq(204)
        expect(File.exist?(File.join(ScanFiles.scan_folder, file))).to be false
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
