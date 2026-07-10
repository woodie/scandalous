require "sinatra/base"
require "humane"
require "json"
require_relative "lib/scan_files"

class WebApp < Sinatra::Base
  helpers do
    def human_size(size)
      Humane::SizeFormatter.new.string(from_byte_count: size)
    end

    def time_ago(time)
      Humane::TimeFormatter.new(approximate: true).string(at: time, relative_to: Time.now)
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
