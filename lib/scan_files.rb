require "fileutils"
require "dotenv/load"
require "time"

class ScanFiles
  ONE_DAY_AGO = Time.now - (24 * 60 * 60)
  Dotenv.load

  class << self
    attr_accessor :scan_folder
  end
  self.scan_folder = File.expand_path("../attachments", __dir__)

  def self.listing
    files = []
    Dir.glob(File.join(scan_folder, "*.pdf")).each do |file|
      name = file.split("/").last
      files << {name: name, time: File.mtime(file), size: File.size(file)}
    end
    files.sort_by { |h| h[:name] }.reverse
  end

  def self.scans_json
    listing.map { |f|
      {
        name: f[:name],
        size: f[:size],
        time: f[:time].iso8601,
        path: "/download/#{f[:name]}"
      }
    }
  end

  def self.cleanup
    Dir.glob(File.join(scan_folder, "*.pdf")).each do |file|
      File.delete(file) if File.file?(file) && File.mtime(file) < ONE_DAY_AGO
    end
  end

  def self.detach(attachments)
    attachments.each do |attachment|
      # Unlike lambada's processAttachments (saves any attachment type), only PDFs are kept here.
      if attachment.content_type.start_with?("application/pdf")
        filename = File.join(scan_folder, "#{Time.now.to_i}.pdf")
        File.open(filename, "w+b", 0o644) { |f| f.write attachment.decoded }
      end
    rescue
      # Unable to save file to disk
    end
  end
end

FileUtils.mkdir_p(ScanFiles.scan_folder) unless File.directory?(ScanFiles.scan_folder)
