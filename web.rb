require "sinatra/base"
require "humane"
require "json"
require_relative "lib/scan_files"

class WebApp < Sinatra::Base
  helpers do
    def human_size(size)
      Humane.human_size(size)
    end

    # approximate: true is no longer passed explicitly -- it's humane-ruby's
    # own default as of v0.9.0. Time.now is no longer passed explicitly
    # either -- Humane.time_ago is a one-argument convenience over
    # Humane.distance_in_time as of humane-ruby v0.9.3, supplying the real
    # clock internally. See docs/releases/2.7.0.md and humane-ruby's own
    # docs/COWORK.md v0.9.3 entry.
    def time_ago(time)
      Humane.time_ago(time)
    end
  end

  # Route to list all available files
  get "/" do
    @listing = ScanFiles.listing
    erb :listing
  end

  # Route to JSON list of files (for zouk client)
  get "/files.json" do
    content_type :json
    ScanFiles.scans_json.to_json
  end

  # Route to download a specific file
  get "/download/:filename" do
    file_path = File.join(ScanFiles.scan_folder, params[:filename])
    if File.exist?(file_path)
      send_file file_path, disposition: :attachment, filename: params[:filename]
    else
      status 404
      "File not found"
    end
  end

  # Route to delete a specific file
  delete "/download/:filename" do
    file_path = File.join(ScanFiles.scan_folder, params[:filename])
    if File.exist?(file_path)
      File.delete(file_path)
      status 204
    else
      status 404
      "File not found"
    end
  end
end
