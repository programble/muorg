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

dest_dir = ARGV[0]
source_dirs = ARGV[1..-1]

# Find all source files
source_files = []

print 'Searching directories: 0 files'

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

# Sort files
dest_paths = {}
utf16 = Iconv.new('UTF-8', 'UTF-16')

print 'Reading ID3 tags:   0%'

source_files.each do |source_file|
  begin
    tags = TagLib2::File.new(source_file)
  rescue TagLib2::BadFile
    next # File has no tags
  end
  
  path = dest_dir
  path = File.join(path, tags.artist) if tags.artist
  path = File.join(path, tags.album) if tags.album
  path = File.join(path, File.basename(source_file))
  dest_paths[source_file] = path
  
  print format("\rReading ID3 tags: %3d%", dest_paths.length.to_f / source_files.length * 100)
end
puts "\rReading ID3 tags: 100%"

#dest_paths.each do |source, dest|
#  puts "#{source} -> #{dest}"
#end
