require "pry"
require "sinatra"
require "fileutils"

DIRECTORY_TO_SERVE = File.expand_path("./files", __dir__)
FileUtils.mkdir_p(DIRECTORY_TO_SERVE) unless File.directory?(DIRECTORY_TO_SERVE)

def as_size(bytes)
  units = %W(B KB MB GB TB PB EB)
  return '0 B' if bytes <= 0
  
  i = (Math.log(bytes) / Math.log(1024)).to_i
  # Ensure we don't go out of bounds of the units array
  i = [i, units.length - 1].min
  
  size = bytes.to_f / (1024**i)
  "%.2f %s" % [size, units[i]]
end

def full_listing
  files = []
  Dir.entries(DIRECTORY_TO_SERVE).reject { |f| File.directory?(f) }.each do |name|
    file = File.join(DIRECTORY_TO_SERVE, name)
    files << {name: name, date: File.mtime(file).rfc2822, size: as_size(File.size file)}
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
  file_path = File.join(DIRECTORY_TO_SERVE, params[:filename])

  if File.exist?(file_path)
    send_file file_path, disposition: :attachment, filename: params[:filename]
  else
    status 404
    "File not found"
  end
end
