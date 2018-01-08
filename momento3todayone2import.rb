#!/usr/bin/env ruby

require 'logger'
require 'time'
require 'tempfile'
require 'shellwords'

### Usage ###
#
# ./momento3todayone2import.rb /path/to/export/folder

### Prerequisites ###
#
# dayone2 CLI
# http://help.dayoneapp.com/day-one-2-0/command-line-interface-cli
#
# Momento Export folder. One file for each day
# https://momento.zendesk.com/hc/en-us/articles/207965865-Export-FAQ

### TODO ###
#
# Journal Option
# Dry Run --> done manually in import! method

class Entry
  attr_accessor :raw, :dir_path

  def initialize(dir_path, raw_text)
    @dir_path = dir_path
    @raw      = raw_text
  end

  def import!(date)
    $logger.info("Importing #{date}")

    datetime = "#{date} #{time}"
    options = cli_options << "--date='#{datetime}'"

    # Note: Journal Flag
    options << "--journal Journal"

    tmp = Tempfile.new(datetime)
    tmp.write(content)
    tmp.rewind
    tmp.close

    cli_cmd = "cat '#{tmp.path}' | dayone2 #{options.join(" ")} new"
    $logger.debug("Command: #{cli_cmd}")
    system(cli_cmd)

    tmp.unlink
  end

  def cli_options
    options = []
    options << "--tags Momento #{tag}"

    options << "--photos #{photo_paths}" unless photo_paths.nil?
    options << "--coordinate #{coordinates}" unless coordinates.nil?

    options
  end

  def time
    time_string = raw.scan(/\d{2}:\d{2}/).first
    time = Time.parse(time_string)
    time.strftime("%H:%M:%S")
  end

  # Future Option: Exclude Time
  # Future Option: Exclude Media
  def content
    @content ||= raw
  end

  def coordinates
    return nil unless feed == "Swarm"
    coords = raw.scan(/At: .+\((.+, .+)\)/).flatten.first
    return nil unless coords
    coords.split(",").map(&:strip).join(" ")
  end

  def tag
    @tag ||= if feed.nil?
      'Journal'
    else
      feed
    end
  end

  def feed
    raw_feed = raw.scan(/Feed: (.+)/).flatten.map(&:strip).first
    return nil if raw_feed.nil?
    feed = raw_feed[/(.+) \(.+\)/, 1]
  end

  def media_filenames
    @media_filenames ||= raw.scan(/Media: (.+)/).flatten.map(&:strip)
  end

  def photo_paths
    return nil if media_filenames.empty?
    media_filenames.collect {|m| Shellwords.escape("#{dir_path}/Attachments/#{m}") }.join(" ")
  end
end

class ExportedFile
  attr_accessor :file_path, :dir_path

  def initialize(dir_path, file_path)
    @dir_path  = dir_path
    @file_path = file_path
  end

  def import_to_dayone
    entries.each do |e|
      e.import!(date)
    end
  end

  # 2 November 2005 --> 2005-11-02
  def date
    date_string = raw_date.sub("\r\n===============", "")
    date = Time.parse(date_string)
    date.strftime("%Y-%m-%d")
  end

  def entries
    @entries ||= raw_entries.collect do |e|
      Entry.new(dir_path, e)
    end
  end

  def contents
    @contents ||= raw_contents.split(/^(?=\d{2}:\d{2})/).map(&:strip)
  end

  private

  def raw_date
    @raw_date ||= contents[0]
  end

  def raw_entries
    @raw_entries ||= contents - [raw_date]
  end

  def raw_contents
    @raw_contents ||= File.read(file_path)
  end
end

class Directory
  attr_accessor :dir_path

  def initialize(dir_path)
    @dir_path = dir_path
  end

  def import!
    $logger.info("Importing #{exported_files.count} Files")
    exported_files.each do |f|
      f.import_to_dayone
    end
  end

  private

  def exported_files
    exported_files = []
    Dir.children(dir_path).sort.each do |f|
      next unless f.end_with?("txt")
      exported_files << ExportedFile.new(dir_path, dir_path + "/#{f}")
    end
    exported_files
  end
end

$logger = Logger.new(STDOUT)
dir_path = ARGV.first
dir      = Directory.new(dir_path)

$logger.info("Importing Momento Files from #{dir_path}")
dir.import!