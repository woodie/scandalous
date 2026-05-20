require "fileutils"

class ScanFiles
  SCAN_FOLDER = File.expand_path("../files", __dir__)
  ONE_DAY_AGO = Time.now - (24 * 60 * 60)

  def self.cleanup
    Dir.glob("#{SCAN_FOLDER}/*.pdf").each do |file|
      File.delete(file) if File.file?(file) && File.mtime(file) < ONE_DAY_AGO
    end
  end

  def self.detach(attachments)
    attachments.each do |attachment|
      if attachment.content_type.start_with?("application/pdf")
        filename = File.join(SCAN_FOLDER, "#{Time.now.to_i}.pdf")
        File.open(filename, "w+b", 0o644) { |f| f.write attachment.decoded }
      end
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  end
end

FileUtils.mkdir_p(ScanFiles::SCAN_FOLDER) unless File.directory?(ScanFiles::SCAN_FOLDER)
