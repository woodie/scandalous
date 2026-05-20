require "action_view"
require "action_view/helpers"

class Formatter
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  def full_listing(scan_folder)
    files = []
    Dir.entries(scan_folder).reject { |f| File.directory?(f) }.each do |name|
      file = File.join(scan_folder, name)
      files << {name: name,
        date: time_ago(File.mtime(file)),
        size: to_human(File.size(file))}
    end
    files.sort_by { |h| h[:name] }.reverse
  end

  def time_ago(time)
    time_ago_in_words(time)
  end

  def to_human(bytes)
    number_to_human_size(bytes)
  end
end
