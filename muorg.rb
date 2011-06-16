#!/usr/bin/env ruby

require 'taglib2'
require 'fileutils'
require 'iconv'

MUSIC_EXTENSIONS = ['.mp3', '.ogg', '.wma', '.m4a', '.flac']

if ARGV.length == 0
  puts 'Usage: muorg.rb <destination> <source>...'
  exit
elsif ARGV.length < 2
  puts 'Error: You must supply at least one source directory'
  exit 1
end

dest_dir = File.expand_path(ARGV[0])
source_dirs = ARGV[1..-1].map {|x| File.expand_path(x)}

# Find all source files
source_files = []

source_dirs.each do |source_dir|
  if File.file? source_dir
    source_files << source_dir
    next
  end
  
  Dir.foreach(source_dir) do |file|
    next if file[0] == '.' # Hey cool, ignore '.', '..', and hidden files!
    file = File.join(source_dir, file)
    if File.directory? file
      source_dirs << file
      next
    end
    source_files << file if MUSIC_EXTENSIONS.include?(File.extname(file))
    
    print "\rSearching directories: #{source_files.length} files" if source_files.length % 100 == 0
  end
end
puts "\rSearching directories: #{source_files.length} files"

if source_files == []
  puts "Error: No music files found"
  exit 1
end

# Sort files
dest_paths = {}

source_files.each do |source_file|
  begin
    tags = TagLib2::File.new(source_file)
  rescue TagLib2::BadFile # File has no tags
    puts "\rWarning: '#{source_file}' is not tagged"
    dest_paths[source_file] = File.join(dest_dir, File.basename(source_file))
    next
  end
  
  path = dest_dir
  path = File.join(path, tags.artist) if tags.artist
  path = File.join(path, tags.album) if tags.album
  path = File.join(path, File.basename(source_file))
  dest_paths[source_file] = path
  
  print format("\rReading tags: %3d%", dest_paths.length.to_f / source_files.length * 100)
end
puts

# Move files (create links for now)
moved_files = 0

dest_paths.each do |source, dest|
  FileUtils.mkdir_p(File.dirname(dest))
  FileUtils.ln_s(source, dest)
  moved_files += 1
  print format("\rCreating links: %3d%", moved_files.to_f / dest_paths.length * 100)
end
puts
