ENV["APP_ENV"] = "test"

require "spec_helper"
require_relative "../web"

RSpec.describe WebApp do
  let(:time) { Time.now.to_i }

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
        get "/download/#{time}.pdf"
        expect(last_response).not_to be_ok
        expect(last_response.status).to eq(404)
      end
    end
  end

  context "with a file" do
    before { File.write(File.join(ScanFiles::SCAN_FOLDER, "#{time}.pdf"), :fake) }

    describe "listing" do
      it "file description" do
        get "/"
        expect(last_response).to be_ok
        expect(last_response.body).to have_tag("h2", text: "Available Scans")
        expect(last_response.body).to have_tag("a", href: "/download/#{time}.pdf")
        expect(last_response.body).to have_tag("a", text: "📄 4 Bytes")
        expect(last_response.body).to have_tag("span", text: "less than a minute ago")
      end
    end

    describe "download actual file" do
      it "responds with 200" do
        get "/download/#{time}.pdf"
        expect(last_response).to be_ok
        expect(last_response.status).to eq(200)
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
  with a file
    listing
      file description
    download actual file
      responds with 200
