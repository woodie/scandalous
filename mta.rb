require "midi-smtp-server"
require "mail"
require_relative "lib/scan_files"

class MySmtpd < MidiSmtpServer::Smtpd
  def on_message_data_event(ctx)
    ScanFiles.cleanup
    Mail.read_from_string(ctx[:message][:data])
    ScanFiles.detach(mail.attachments)
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
