require "sinatra/base"
require "action_view"
require "action_view/helpers"
require "json"
require_relative "lib/scan_files"

class WebApp < Sinatra::Base
  include ActionView::Helpers::DateHelper

  helpers do
    # Matches Finder: 1000-based math, capitalized KB/MB/... labels.
    def human_size(size)
      units = %w[B KB MB GB TB PB EB]
      return "#{size} B" if size < 1000

      exponent = [(Math.log(size) / Math.log(1000)).to_i, units.size - 1].min
      rounded = (size / (1000.0**exponent) * 10).round / 10.0
      rounded < 10 ? format("%.1f %s", rounded, units[exponent]) : format("%.0f %s", rounded, units[exponent])
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
