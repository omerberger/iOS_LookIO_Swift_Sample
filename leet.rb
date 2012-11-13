file_out = File.open "leet.strings.erl", "w"
file_in = File.open "Localizable.strings", "r"
lines = {}
orig = {}
file_in.each_line do |line|
	tokens = line.scan(/^"(.+)" = "(.+)"/).flatten
	next unless tokens.count > 0
	orig[tokens[0]] = tokens[1]
	result = tokens[1].downcase.gsub /the/, "teh"
	result = result.gsub /you/, "u"
	result = result.gsub /[iaseot]/, { "i" => "1", "a" => "4", "s" => "5", "e" => "3", "o" => "0", "t" => "7" }

	lines[tokens[0]] = result
end
file_in.close

#file_out.puts "{"
#count = 0
lines.each do |k|
	oh = "{\"#{k[0]}\", \"#{k[1]}\"}."
	#oh << "," if count < lines.count - 1
	file_out.puts oh
	#count = count + 1
end
#file_out.puts "}"
file_out.close

#count = 0
File.open "english.strings.erl", "w" do |lol|
	#lol.puts "{"
	orig.each do |k|
		hi = "{\"#{k[0]}\", \"#{k[1]}\"}."
		#hi << "," if count < orig.count - 1
		lol.puts hi
		#count = count + 1
	end
	#lol.puts "}"
end