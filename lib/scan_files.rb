require "fileutils"
require "dotenv/load"
require "net/http"
require "resolv"
require "uri"

class ScanFiles
  SCAN_FOLDER = File.expand_path("../files", __dir__)
  ONE_DAY_AGO = Time.now - (24 * 60 * 60)
  Dotenv.load

  def self.interface
    ext_host = ENV["EXT_HOST"] || "examle.com"
    actual = Net::HTTP.get_response(URI("https://api.ipify.org"))&.body
    stored = Resolv.getaddress(ext_host)
    if actual == stored
      "✅ #{ext_host} = #{actual}"
    else
      "⛔ #{ext_host} ≠ #{actual}"
    end
  end

  def self.listing
    files = []
    Dir.glob(File.join(SCAN_FOLDER, "*.pdf")).each do |file|
      name = file.split('/').last
      files << {name: name, time: File.mtime(file), size: File.size(file)}
    end
    files.sort_by { |h| h[:name] }.reverse
  end

  def self.cleanup
    Dir.glob(File.join(SCAN_FOLDER, "*.pdf")).each do |file|
      File.delete(file) if File.file?(file) && File.mtime(file) < ONE_DAY_AGO
    end
  end

  def self.detach(attachments)
    attachments.each do |attachment|
      if attachment.content_type.start_with?("application/pdf")
        filename = File.join(SCAN_FOLDER, "#{Time.now.to_i}.pdf")
        File.open(filename, "w+b", 0o644) { |f| f.write attachment.decoded }
      end
    rescue
      # Unable to save file to disk
    end
  end
end

FileUtils.mkdir_p(ScanFiles::SCAN_FOLDER) unless File.directory?(ScanFiles::SCAN_FOLDER)
