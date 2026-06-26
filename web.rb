require "sinatra/base"
require "action_view"
require "action_view/helpers"
require "json"
require "time"
require_relative "lib/scan_files"

class WebApp < Sinatra::Base
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  # Route to list all available files
  get "/" do
    @listing = ScanFiles.listing
    @interface = ScanFiles.interface
    erb :listing
  end

  # Route to JSON list of files (for zouk client)
  get "/scans.json" do
    content_type :json
    ScanFiles.listing.map { |f|
      {
        name: f[:name],
        size: f[:size],
        time: f[:time].iso8601,
        url: "/download/#{f[:name]}"
      }
    }.to_json
  end

  # Route to download a specific file
  get "/download/:filename" do
    file_path = File.join(ScanFiles::SCAN_FOLDER, params[:filename])
    if File.exist?(file_path)
      send_file file_path, disposition: :attachment, filename: params[:filename]
    else
      status 404
      "File not found"
    end
  end
end
