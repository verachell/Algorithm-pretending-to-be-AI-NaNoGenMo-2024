TEXT_SOURCES = ["Data/anne-pg45.txt", "Data/leagues-pg164.txt", "Data/highways-pg29420.txt", "Data/astronomy-pg34834.txt"]
DESIRED_WORD_COUNT = 50000
COMMON_WORD_NUM = 1000
START_WORD_NUM = 400
END_WORD_NUM = 200
KW_EXACT_MATCH = true

def clean_book(fname)
	# reads text file and returns its contents as a string
	# with some punctuation normalized
	raw_txt = File.read(fname)
	raw_txt.tr!("\“\”", "\"")
	raw_txt.tr!("‘’", "'")
	raw_txt.tr!("_", "")
	raw_txt
end

def word_freq_hash(word_arr)
	# given an array of words (whitespace splitted text string)
	# returns a hash with the word and its frequency number
	result = Hash.new
	word_arr.each{|word|
			if result.has_key?(word)
				result[word] = result[word] + 1
			else
				result[word] = 1
			end
	}
	result
end

def start_word?(word)
	(word.match?(/^[A-Z]/) or word.match?(/^[\"][A-Z]/)) and (word.match?(/\.$/) == false)
end

def end_word?(word)
	reg_endings = [/[a-z]\.$/, /[a-z][\!\?]$/, /[a-z]\"\.$/, /[a-z][\?\!]$/, /[a-z][\.\!\?]\"$/]
	reg_endings.any?{|reg| word.match?(reg)} and ((word != "Mrs.") and (word != "Dr.") and (word != "Mr."))
end

def end_word_dialog?(word)
	end_word?(word) and word.include?("\"") and (word.start_with?("\"") == false)
end

def end_word_no_dialog?(word)
	end_word?(word) and (word.include?("\"") == false)
end

def middle_word?(word)
	(start_word?(word) == false) and (end_word?(word) == false)
end

def start_with_dialog?(str)
	# returns true if string starts with quotation mark, false otherwise
	str.start_with?("\"")
end

def get_word_splitters(freq_arr, desired_word_num, use_method)
	# from the word frequency array, returns an array of frequently used words
	# to split the text with. The &block argument allows selection of types
	# of words, for example start words, end words and middle words
	# most of the words in the frequency array will be middle words
	result = Array.new
	freq_arr.each{|word|
		if use_method.call(word)
			result << word
		end
		if result.size >= desired_word_num
			return result
		end	
	}
	# if the text is small compared to desired_word_num, we may have to return
	# a smaller than desired result
	result
end

def add_str_to_grid(str, h, lkey, rkey)
	if h.has_key?(lkey)
		row = h[lkey]
		if row.has_key?(rkey)
			if h[lkey][rkey].include?(str) == false
				# only include it if it doesn't already exist
				h[lkey][rkey] << str
			end
		else
			h[lkey][rkey] = [str]
		end
	else
		# need to add it in from scratch
		nested_h = { rkey => [str] }
		h[lkey] = nested_h
	end
	h
end

def generate_frag_grid(text_word_arr, splitter_arr)
	# from word splitter array, generate a 2D grid in the form of a hash
	# where primary index corresponds to the first word in a fragment and secondary
	# index corresponds to last word in a fragment
	# Fragments are generated from the raw text word array, where we cut the text
	# at every word in the word splitter array.
	frag_grid = Hash.new
	curr_frag = ""
	new_frag = true
	start_word = ""
	last_ind = text_word_arr.length - 1
	# account for multiple splitters in a row
	text_word_arr.each{|word|
		# the word is either a splitter or a non-splitter
		if splitter_arr.include?(word)
			# it's a splitter so it either goes at the start or end of a fragment
			if new_frag
				# it's at the start of a fragment
				if splitter_arr.include?(curr_frag.strip)
					# need to account for a new_frag that is followed by 
					# another splitter, can't just add it to curr_frag
					# need to close off that one and add it to grid
					curr_frag << word
					add_str_to_grid(curr_frag.strip, frag_grid, start_word, word)
					# reset variables
					new_frag = true
					curr_frag = word + " "
					start_word = word
				else
					curr_frag << word << " "
					start_word = word
					new_frag = false
				end
			else
				# it's at the end of a fragment - need to store in hash
				# and put that word at the start of the next fragment
				curr_frag << word
				add_str_to_grid(curr_frag.strip, frag_grid, start_word, word)
				# reset variables
				new_frag = true
				curr_frag = word + " "
				start_word = word
			end
		else
			# it's not a splitter
			if curr_frag != ""
				curr_frag << word << " "
				new_frag = false
			end
		end
	}
	frag_grid
end

def get_kw_frags(row_arr, keyword_arr)
	if keyword_arr.empty?
		return nil
	else
		result = Array.new
		row_arr.each{|item|
			str_arr = item[1]
			str_arr.each{|frag| 
				keyword_arr.each{|kw| 
					if KW_EXACT_MATCH
						reg = /\b#{kw}\b/
						if frag.dup.downcase.match?(reg)
							result << frag
						end
					else
						if frag.dup.downcase.include?(kw.dup.downcase)
							result << frag
						end
					end
				}
			}
		}
	end
	# if result is empty return false, otherwise return sample
	if result.empty?
		return nil
	else
		return result.sample
	end
end

def lookup_grid(lindex, grid, keyword_arr = [])
	# given the index of the start of the fragment,
	# returns a random fragment from the grid as a text string
	if grid.has_key?(lindex)
		grid_row = grid[lindex]
		row_arr = grid_row.to_a
		# next see if we can find anything containing our keywords
		kw_frag = get_kw_frags(row_arr, keyword_arr)
		if kw_frag != nil
			return kw_frag
		else
			thing = row_arr.sample
			return thing[1].sample
		end
	else
		puts "lookup error - could not find a row of data for the word"
		p lindex
		""
		exit
	end
end

def remove_last_word_from_str(str)
	# removes last word from string. If only one word present, returns string
	rind = str.rindex(" ")
	if rind == nil
		str
	else
		str[0..(rind - 1)]
	end
end

def last_word(str)
	# returns the last word from string.  If only one word present, returns string
	rind = str.rindex(" ")
	if rind == nil
		str
	else
		str[(rind + 1)..(str.length - 1)]
	end
end

def word_count(str)
	# returns word count using simplest method
	str.count(" ") + 1
end

def generate_filename(keywords = [])
	bname = "Story_"
	if keywords != []
		keywords.reduce(bname){|changing, arritem|
		changing << arritem << "_"}
	end
	4.times do
		bname << rand(9).to_s
	end
	bname << ".md"
	bname
end

def string_keywords(kw_arr)
	# given an array of keywords, strings them together
	# in a human-friendly manner using commas and/or the word 'and'
	str = ""
	len = kw_arr.size
	if len == 1
		'"' + kw_arr[0] + '"'
	elsif len == 2
		'"' + kw_arr[0] + '" and "' + kw_arr[1] + '"'
	else
		(0..(len - 2)).each{|ind| str << '"' << kw_arr[ind] << '", ' }
		str << 'and "' << kw_arr[(len - 1)] << '"'
		str
	end
end

def final_keywords(user_keywords, freq_hash)
	# given an array of user keywords and frequency hash list, removes from 
	# user_keywords any keywords which are not present in the frequency hash
	# and returns the resultant subset of keywords as an array.
	# Reports any removals as a warning to the user.
	# Also warns the user if rare keywords are specified, although continues
	# as normal if using rare ones.
	threshold = 5
	result = Array.new
	zero = Array.new
	few = Array.new
	ok = Array.new
	user_keywords.each{|kw|
		if freq_hash.has_key?(kw)
			freq = freq_hash[kw]
			if freq < threshold
				few << kw
			else
				ok << kw
			end
		else
			zero << kw
		end
	}
	unless few.empty?
		if KW_EXACT_MATCH
			extra_word_info = ""
		else
			extra_word_info = "However, I may use other words containing that word."
		end
		puts "* I don't have much information in my data about #{string_keywords(few)} but will proceed. The consequence is that #{string_keywords(few)} may be rare in the output. #{extra_word_info} \n\n"
	end
	unless zero.empty?
		puts "* I don't have any information in my data involving #{string_keywords(zero)}. Therefore #{string_keywords(zero)} won't appear in the final output\n\n"
	end
	unless ok.empty?
		puts "* I have information about #{string_keywords(ok)}\n\n"
	end
	result = ok + few
	if result.empty?
		puts "Sorry, I can't continue. I don't have information in my data about any of the keywords you entered"
		exit
	else
		puts "\nHere is a #{DESIRED_WORD_COUNT} word story about #{string_keywords(result)}\n"
	end
	result
end

def get_user_keywords
	# receives user input and converts this to an array of words
	print "\nEnter your desired keywords separated by spaces: "
	user_in = gets
	raw_kw = user_in.split
	clean_kw = Array.new
	raw_kw.each{|user_kw| 
		temp = user_kw.downcase.tr('^a-z', "")
		if temp != ""
			clean_kw << temp
		end
	}
	clean_kw
end

# start
puts "Getting text..."

all_str = ""
TEXT_SOURCES.each{|filename| all_str << clean_book(filename)}
text_arr = all_str.split(/\s/)

# clean up text_arr - it will contain non-words
clean_arr = Array.new
text_arr.each{|splitted|
	if (splitted.match?(/[A-Za-z]/)) and (splitted.match?(/[a-z]/) or splitted.length < 6) and (splitted.match?(/[\=\^\*@#\]\}\}\(\)\[\|]/) == false)
		clean_arr << splitted
	end
}

## Get keywords
user_keywords = get_user_keywords

puts "Sorting out words...\n"
freq_hash = word_freq_hash(clean_arr)
freq_arr = freq_hash.to_a
freq_arr.sort_by!{|item| item[1]}
word_arr_ordered = freq_arr.reverse!.map{|item|
	item[0]
}

# need to tidy up keywords a bit
keywords = final_keywords(user_keywords, freq_hash)

print "Creating word tables... please be patient"
middle_splitter_arr = get_word_splitters(word_arr_ordered, COMMON_WORD_NUM, method(:middle_word?))
start_splitter_arr = get_word_splitters(word_arr_ordered, START_WORD_NUM, method(:start_word?))
print "."
end_dialog_splitter_arr = get_word_splitters(word_arr_ordered, END_WORD_NUM, method(:end_word_dialog?))
end_no_dialog_splitter_arr = get_word_splitters(word_arr_ordered, END_WORD_NUM, method(:end_word_no_dialog?))

print "."
start_middle_arr = start_splitter_arr + middle_splitter_arr
start_middle_end_dialog_arr = start_splitter_arr + middle_splitter_arr + end_dialog_splitter_arr
start_middle_end_no_dialog_arr = start_splitter_arr + middle_splitter_arr + end_no_dialog_splitter_arr

print "."
start_middle_grid = generate_frag_grid(clean_arr, start_middle_arr)
print "."
start_middle_end_dialog_grid = generate_frag_grid(clean_arr, start_middle_end_dialog_arr)
print ".\n"
start_middle_end_no_dialog_grid = generate_frag_grid(clean_arr, start_middle_end_no_dialog_arr)

### Start generating the story ####
puts "\n"
print "Generating the story. This could take a few minutes..."
story = ""
quarterway_reported = false
halfway_reported = false
threequarter_reported = false

while word_count(story) < DESIRED_WORD_COUNT
	# use a start word
	start_word = start_splitter_arr.sample
	frag = lookup_grid(start_word, start_middle_grid, keywords)
	frag_end = last_word(frag.dup)
	old_frag = frag.dup
	story << remove_last_word_from_str(frag) << " "
	# depending if we started with dialog, need to use a grid that
	# ends with dialog, and vice versa
	if start_with_dialog?(frag)
		use_grid = start_middle_end_dialog_grid
	else
		use_grid = start_middle_end_no_dialog_grid
	end
	print "."
	if word_count(story) > (DESIRED_WORD_COUNT / 4) and (quarterway_reported == false)
		print " Quarter of the way there "
		quarterway_reported = true
	end
	if word_count(story) > (DESIRED_WORD_COUNT / 2) and (halfway_reported == false)
		print " Halfway there! "
		halfway_reported = true
	end
	if word_count(story) > (DESIRED_WORD_COUNT * 3 / 4) and (threequarter_reported == false)
		print " Three quarters completed "
		threequarter_reported = true
	end
	# make a sentence - continue getting fragments from 
	# appropriate grid until we get an end word
	until end_word?(frag_end)
		frag = lookup_grid(frag_end, use_grid, keywords)
		# rarely, it is possible with keyword usage to wind up in an endless
		# loop because the only keyword fragment available both begins and ends
		# with the same first and last word, forcing it to be continually chosen
		# e.g. in town in (where keyword is town)
		# therefore, break out of the loop if first and last fragment are the same
		if frag == old_frag
			break
		end
		frag_end = last_word(frag.dup)
		if end_word?(frag_end)
			story << frag << "\n\n"
		elsif start_with_dialog?(frag)
			story << "\n\n" << remove_last_word_from_str(frag) << " "
		else
			story << remove_last_word_from_str(frag) << " "
		end
		old_frag = frag.dup
	end # until loop
end # while loop
# need to add an ending word if it doesn't already have an ending word
if story.end_with?(" ")
	story << end_no_dialog_splitter_arr.sample
end

puts "\n"
## output the story in a file
fname = generate_filename(keywords)
puts "Completed. Writing story to file #{fname}"
File.write(fname, story)