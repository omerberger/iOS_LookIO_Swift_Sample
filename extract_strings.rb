#!/usr/bin/ruby
require 'digest/md5'

def leetify(string)
	result = string.downcase.gsub /the/, "teh"
	result = result.gsub /you/, "u"
	result = result.gsub /i/, "1"
	result = result.gsub /a/, "4"
	result = result.gsub /s/, "5"
	result = result.gsub /e/, "3"
	result = result.gsub /o/, "0"
	result = result.gsub /t/, "7"
	result
end

table = {}
all_keys = []
File.open ARGV[0], "r" do |file_in|
	file_in.each_line do |line|
		next unless line.chomp.length > 0 and line.start_with? "\""
		tokens = line.scan(/"(.+)"\s*=\s*"(.+)";/).flatten
		value = tokens[1]
		value = leetify value if ARGV[1] == "leet"
		table[tokens[0]] = value
		puts "{\"#{tokens[0]}\", \"#{value}\"}."
		all_keys << tokens[0]
	end
end

hash_input = ""
all_keys.sort.each do |key|
	hash_input << table[key]
end

hash_input = eval "\"#{hash_input}\""
digest = Digest::MD5.hexdigest hash_input

puts all_keys.sort
puts
puts hash_input
puts
puts digest
puts