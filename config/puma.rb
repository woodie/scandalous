rackup "config.ru"

environment ENV.fetch("RACK_ENV") { "development" }

bind "tcp://0.0.0.0:8080"

__END__

ssl_bind '0.0.0.0', 8443, {
  key: '/path/to/server/key',
  cert: '/path/to/server/cert'
}
