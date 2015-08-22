#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'

puts "Checking that dependencies are met......."
if !`gem list`.include?("nokogiri")
  puts "Could not find Nokogiri gem.  Attempting install."
  if !system("gem install nokogiri")
    puts "Failed to install Nokogiri gem."
    puts "You might want to try to install it yourself."
    exit 1
  end
end

require 'nokogiri'

ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
CONTENT_DIR = File.expand_path(File.join(ROOT_DIR, "content"))
BIN_DIR = File.expand_path(File.join(ROOT_DIR, "bin"))

def root_path(name); File.join(ROOT_DIR, name); end
def content_path(name); File.join(CONTENT_DIR, name); end
def bin_path(name); File.join(BIN_DIR, name); end

def parse(filename)
  Nokogiri::HTML(File.read filename) do |config|
    config.options = Nokogiri::XML::ParseOptions::STRICT
  end
end

def write(doc, filename)
  File.open(filename, "w") { |f| f.write(doc.to_xhtml) }
end

def normalize(name)
  File.basename(name).gsub(" ", "").gsub("%20", "").downcase.gsub(".html", "")
end

puts "Reading and parsing FrontMatter.html"
front_matter_path = content_path("FrontMatter.html")
html_doc = parse(front_matter_path)

puts "Collecting filenames from FrontMatter table of contents"
filelist = []
links = html_doc.css("a").each do |a|
  filename = content_path(a["href"])
  filelist << filename
  a["href"] = "##{normalize(filename)}"
end

puts "Composing contents of each file into FrontMatter"
doc_body = html_doc.at_css("body")
filelist.each do |f|
  poem = parse(f)
  title = normalize(f)
  doc_body << "\n<!-- STARTING SECTION: #{title} -->\n"
  doc_body.add_child(poem.at_css("body").children)
  doc_body << "\n<!-- ENDING SECTION: #{title} -->\n"
end

puts "Writing final HTML file as index.html"
File.open(root_path("index.html"), "w") { |f| f.write(html_doc.to_html) }

puts "Generating manifest file."
SHA = `git log -n 1 --format="%h" -- #{CONTENT_DIR}`
manifest = <<MANIFEST
Generated against #{SHA}
Output From Kindlegen:
MANIFEST
File.open(root_path("manifest.txt"), "w") { |f| f.write(manifest) }

puts "Generating eBook using kindlegen"
def kindlegen_bin
  return "kindlegen-darwin" if /darwin/i =~ RUBY_PLATFORM
  return "kindlegen-win32" if /cygwin|mswin|mingw|bccwin|wince|emx/i =~ RUBY_PLATFORM
  return "kindlegen-linux" # whatevs, default to linux.
end

system("#{bin_path(kindlegen_bin)} #{root_path('index.html')} >> #{root_path("manifest.txt")} 2>&1")

puts File.read(root_path("manifest.txt"))
