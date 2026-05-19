require "sinatra"
require "action_view"
require "action_view/helpers"

set :port, 8080
set :bind, "0.0.0.0"

SCAN_FOLDER = File.expand_path("./files", __dir__)

def full_listing
  files = []
  Dir.entries(SCAN_FOLDER).reject { |f| File.directory?(f) }.each do |name|
    file = File.join(SCAN_FOLDER, name)
    files << {name: name,
      date: Format.new.when(File.mtime(file)),
      size: Format.new.size(File.size(file))}
  end
  files.sort_by { |h| h[:name] }.reverse
end

# Route to list all files in the directory
get "/" do
  @files = full_listing

  erb :full_listing
end

# Route to download a specific file
get "/download/:filename" do
  file_path = File.join(SCAN_FOLDER, params[:filename])

  if File.exist?(file_path)
    send_file file_path, disposition: :attachment, filename: params[:filename]
  else
    status 404
    "File not found"
  end
end

class Format
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  def when(time)
    time_ago_in_words(time)
  end

  def size(bytes)
    number_to_human_size(bytes)
  end
end
