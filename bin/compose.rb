#!/usr/bin/env ruby

require 'fileutils'
require 'nokogiri'
require 'pathname'

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

front_matter_path = content_path("FrontMatter.html")
html_doc = parse(front_matter_path)

filelist = []
links = html_doc.css("a").each do |a|
  filename = content_path(a["href"])
  filelist << filename
  a["href"] = "##{normalize(filename)}"
end

doc_body = html_doc.at_css("body")
filelist.each do |f|
  poem = parse(f)
  title = normalize(f)
  doc_body << "\n<!-- STARTING SECTION: #{title} -->\n"
  doc_body.add_child(poem.at_css("body").children)
  doc_body << "\n<!-- ENDING SECTION: #{title} -->\n"
end

# Write final HTML file.
File.open(root_path("index.html"), "w") { |f| f.write(html_doc.to_html) }

# Generate MANIFEST file.
SHA = `git log -n 1 --format="%h" -- #{CONTENT_DIR}`
manifest = <<MANIFEST
Generated on #{Time.now.to_s}
Against #{SHA}
Output From Kindlegen:
MANIFEST
File.open(root_path("manifest.txt"), "w") { |f| f.write(manifest) }

# Generate Ebook
system("#{bin_path("kindlegen")} #{root_path('index.html')} >> #{root_path("manifest.txt")} 2>&1")

puts File.read(root_path("manifest.txt"))
