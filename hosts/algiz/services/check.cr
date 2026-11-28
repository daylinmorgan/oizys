#! /usr/bin/env nix-shell
#! nix-shell -i crystal -p crystal crane

require "json"
require "semantic_version"
require "colorize"

module Crane
  @@bin = Process.find_executable("crane") || raise "crane not found in PATH"
  def self.ls(url : String) Array(String)
    output = IO::Memory.new
    status = Process.run(@@bin, ["ls", url], output: output, error: Process::Redirect::Inherit)
    raise "crane ls failed for #{url}" unless status.success?
    output.to_s.lines(chomp: true)
  end
end

images_file = File.join(__DIR__, "images.nix")
raw_json = `nix eval -f #{images_file.inspect} --json`
raise "nix eval failed" unless $?.success?

puts "ignoring redis!"
data = Hash(String, String).from_json(raw_json).select { |k, _| k != "redis" }

def tag_to_version(tag : String) : SemanticVersion?
  base = tag.split('-', 2).first.lstrip('v')
  SemanticVersion.parse?(base)
end

def get_sorted_version_tags(url : String) : Array(SemanticVersion)
  parsed = Crane.ls(url).map { |tag| tag_to_version(tag) }
  tags = parsed.compact.sort.reverse!
  puts ">> #{tags.size}/#{parsed.size} version-like tags".colorize.cyan
  tags
end

def check_for_updates(service : String, current_ref : String)
  url, current_tag = current_ref.split(':', 2)
  puts "checking #{service.colorize.bold}, current: #{current_tag}"
  sorted_tags = get_sorted_version_tags(url)
  unless sorted_tags
    puts "no tags found!"
    return
  end
  latest_version = sorted_tags.first
  current_version = tag_to_version(current_tag)
  if current_version.nil?
    puts "current version isn't valid".colorize.red
    return
  end
  if current_version < latest_version
    puts "Update available for #{service}: #{current_version} -> #{latest_version}".colorize.green
  end
end

data.each do |service, ref|
  check_for_updates(service, ref)
end
