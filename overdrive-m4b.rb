# encoding: utf-8

require 'pry'
require 'optparse'
require 'id3tag'
require 'nokogiri'

def with_exit
  out = yield
  exit($?.exitstatus) if $?.exitstatus != 0
  out
end

def ts_to_s(ts)
  m = ts.match(/((?<hh>\d+):)?(?<mm>\d+):(?<ss>\d+)\.(?<ms>\d+)/)
  o = m.names.map(&:to_sym).zip(m.captures.map(&:to_i)).to_h
  o[:hh]*60*60 + o[:mm]*60 + o[:ss] + o[:ms] / 1000.0
end

def s_to_ts(s)
  hh = s/60/60
  mm = s/60 % 60
  ss = (s - (hh*60*60 - mm*60)) % 60
  [hh, mm, ss.to_i, ((s - s.to_i)*1000).to_i]
end

def get_chapters_shell(path)
  raw = with_exit do
    `id3info #{path.shellescape} |
     grep "^=== TXXX (User defined text information): (OverDrive MediaMarkers): " |
     cut -d':' -f3- |
     xidel -se "//Marker/(concat(Time/text(), ' ', Name/text()))" -`
  end
  raw.split("\n").map do |r|
    ts, name = r.split(' ', 2)
    [ts_to_s(ts), name]
  end
end

def get_chapters(path)
  id3 = ID3Tag.read(File.open(path, 'rb'))
  txxx = [*id3.get_frame(:TXXX)].find { |f| f.description == "OverDrive MediaMarkers" }
  return [] if txxx.nil?
  doc = Nokogiri::HTML(txxx.content)
  doc.css('time').map { |t| ts_to_s(t.text.strip) }.zip(doc.css('name').map { |s| s.text.strip })
end

def make_chapters_file
  chapters_per_file = $paths.map(&method(:get_chapters))
  duration_per_file = $paths.map do |p|
    with_exit do `ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{p.shellescape}`.to_f end
  end
  last_ch_duration = duration_per_file.zip(chapters_per_file.map { |l| l.last.first }).map { |d, c| d - c }

  (0...chapters_per_file.size-1).zip((1...chapters_per_file.size)).each do |i, j|
    base_ts = chapters_per_file[i].last.first + last_ch_duration[i]
    chapters_per_file[j].each { |ch| ch[0] = ch[0] + base_ts }
  end

  open($chapters_output, 'w') do |f|
    chapters_per_file.flatten(1).each do |c|
      s, name = c
      f << "%02d:%02d:%02d.%03d %s\n" % [*s_to_ts(s), name]
    end
  end
end

def embed_chapters
  make_chapters_file
  with_exit { `mp4chaps -i #{$output.shellescape} && rm #{$chapters_output.shellescape}` }
end

def embed_cover
  cover = ['600x600bb.jpg', 'cover.jpg', 'folder.jpg'].map { |f| File.join($dir, f) }.find(&File.method(:exist?))
  with_exit { `mp4art --add #{cover.shellescape} #{$output.shellescape}` } unless cover.nil?
end

def get_input(msg)
  print "#{msg}: "; STDOUT.flush
  STDIN.gets.chomp
end

options = OpenStruct.new

optparser = OptionParser.new('overdrive-m4b [options] <mp3-files>') do |p|
  p.on('-g GENRE', '--genre=GENRE') { |g| options.genre = g }
  p.on('-t TITLE', '--title=TITLE') { |t| options.title = t }
  p.on('-a AUTHOR', '--author=AUTHOR') { |a| options.author = a }
  p.on('--merge') { |b| options.merge = b }
  p.on('--tags') { |b| options.tags = b }
  p.on('--chapters') { |b| options.chapters = b }
  p.on('--cover') { |b| options.cover = b }
  p.parse!
end

actions = [:merge, :tags, :chapters, :cover]
if actions.all? { |a| options.send(a).nil? }
  actions.each { |a| options.send("#{a}=".to_sym, true) }
end

if ARGV.empty?
  puts optparser.help
  exit(1)
end

$paths = ARGV.map { |p| File.expand_path(p) }
$dir = File.dirname($paths.first)
id3 = ID3Tag.read(File.open($paths.first, 'rb'))
author = options.author || id3.artist || get_input("Author")
title = options.title || id3.album || get_input("Title")
genre = options.genre || get_input("Genre")
$output = "#{author} - #{title}.m4b"
$chapters_output = "#{author} - #{title}.chapters.txt"

with_exit do
  `ffmpeg -i 'concat:#{$paths.join('|')}' -map 0 -map -v -c:a libfdk_aac -vbr 4 -f mp4 #{$output.shellescape}`
end if options.merge
with_exit { `mp4tags -rs -g "#{genre}" -a "#{author}" -A "#{title}" #{$output.shellescape}` } if options.tags
embed_chapters if options.chapters
embed_cover if options.cover

