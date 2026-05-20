require "fileutils"
require "midi-smtp-server"
require "mail"

ONE_DAY_AGO = Time.now - (24 * 60 * 60)
SCAN_FOLDER = File.expand_path("./files", __dir__)
FileUtils.mkdir_p(SCAN_FOLDER) unless File.directory?(SCAN_FOLDER)

class MySmtpd < MidiSmtpServer::Smtpd
  def on_message_data_event(ctx)
    ditch_old_pdf_scans
    write_new_pdf_scans
  end

  def ditch_old_pdf_scans
    Dir.glob("#{SCAN_FOLDER}/*.pdf").each do |file|
      File.delete(file) if File.file?(file) && File.mtime(file) < ONE_DAY_AGO
    end
  end

  def write_new_pdf_scans
    Mail.read_from_string(ctx[:message][:data])
    mail.attachments.each do |attachment|
      if attachment.content_type.start_with?("application/pdf")
        filename = File.join(SCAN_FOLDER, "#{Time.now.to_i}.pdf")
        File.open(filename, "w+b", 0o644) { |f| f.write attachment.decoded }
      end
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
  end
end

server = MySmtpd.new(ports: 2525, hosts: "0.0.0.0")

# save flag for Ctrl-C pressed
flag_status_ctrl_c_pressed = false

# try to gracefully shutdown on Ctrl-C
trap("INT") do
  puts
  flag_status_ctrl_c_pressed = true
  exit 0
end

# setup exit code
at_exit do
  server&.stop
end

# Start the server
server.start

# Run on server forever
server.join
