#!/usr/bin/env ruby

require "yaml"

if ARGV.length != 2
  warn "usage: transform_airport1_provider.rb INPUT_YAML OUTPUT_YAML"
  exit 1
end

input_path, output_path = ARGV
data = YAML.load_file(input_path)
proxies = data["proxies"]

unless proxies.is_a?(Array)
  warn "expected top-level 'proxies' array in #{input_path}"
  exit 1
end

proxies.each do |proxy|
  next unless proxy.is_a?(Hash)
  next unless proxy["type"] == "trojan"
  next if proxy.key?("client-fingerprint")

  proxy["client-fingerprint"] = "chrome"
end

rendered = YAML.dump(data)
if File.exist?(output_path) && File.read(output_path) == rendered
  exit 0
end

File.write(output_path, rendered)
