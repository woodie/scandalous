require "sinatra"
require_relative "lib/scan_files"
require_relative "lib/formatter"

set :port, 8080
set :bind, "0.0.0.0"

# Route to list all files in the directory
get "/" do
  @listing = Formatter.new.listing(ScanFiles::SCAN_FOLDER)
  erb :listing
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
