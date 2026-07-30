require "rack/test"
require "rspec-html-matchers"
require "tmpdir"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include RSpecHtmlMatchers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Global, not per-file: every spec that touches ScanFiles.scan_folder
  # (scan_files_spec.rb, web_spec.rb) gets a fresh tmpdir instead of the
  # real attachments/ folder. This used to live only in scan_files_spec.rb's
  # own `around` block, so web_spec.rb's `before { FileUtils.rm_rf(...) }`
  # ran against the real folder untouched -- deleting real scanned PDFs on
  # every run. Defining it once here means no spec file can forget to opt in.
  config.around do |example|
    Dir.mktmpdir do |dir|
      original_scan_folder = ScanFiles.scan_folder
      ScanFiles.scan_folder = dir
      example.run
      ScanFiles.scan_folder = original_scan_folder
    end
  end
end
