require "fileutils"
require "midi-smtp-server"
require "mail"

DIRECTORY_TO_SERVE = File.expand_path("./files", __dir__)
FileUtils.mkdir_p(DIRECTORY_TO_SERVE) unless File.directory?(DIRECTORY_TO_SERVE)
OLD_FILE_THRESHOLD = Time.now - (24 * 60 * 60) # 24 hours ago

class MySmtpd < MidiSmtpServer::Smtpd
  def on_message_data_event(ctx)
    mail = Mail.read_from_string(ctx[:message][:data])
    mail.attachments.each do |attachment|
      if attachment.content_type.start_with?("application/pdf")
        filename = File.join(DIRECTORY_TO_SERVE, "#{Time.now.to_i}.pdf")
        File.open(filename, "w+b", 0o644) { |f| f.write attachment.decoded }
      end
    rescue => e
      puts "Unable to save data for #{filename} because #{e.message}"
    end
    Dir.glob(DIRECTORY_TO_SERVE + "/*.pdf").each do |file|
      File.delete(file) if File.file?(file) && File.mtime(file) < OLD_FILE_THRESHOLD
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
