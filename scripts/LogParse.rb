#!/usr/bin/ruby
#
# Parse ATCS log file formatted log and return block occupancy
#
#
#

require 'pp'
require 'set'

#configuration
# logfile = "ATCSTestLog.txt"
# logfile = "../testAllATCSLog.txt"
logfile = ARGV.first

p "parsing #{logfile}"

#globals
$events = []
$blockEvents = ["BEAK", "BWAK", "BSAK", "BNAK", "AOK"]

#_______________________________________________________________________________________
# Classes
#_______________________________________________________________________________________

class String
 def string_between_markers marker1, marker2
   self[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
 end
end


class MnemonicEvent
	def initialize(mnemonics = "none", mcpname = "none", date=nil) 
		@mnemonics = mnemonics 
		@mcpname = mcpname
		@date = date
		@isOccupied = false
	end

	attr_reader :mnemonics, :mcpname, :date, :isOccupied
	attr_writer :mnemonics, :mcpname, :date, :isOccupied

	def eventString
		s = @mnemonics.scan(/[\w'-]{3,}/)
		p "#{s}"
	end

	def to_s
	  attributes.each_with_object("") do |attribute, result|
	    result << "#{attribute[1].to_s} "
	  end
	end
end  


def matchDateStr(str) 
	regex = /\d{4}\/\d{2}\/\d{2}/
	if str =~ regex
	   return true
	end
	return false
end 

def isBadEvent(event)
	return event.mcpname.eql?("none") || event.mnemonics.eql?("none") 
end



#_______________________________________________________________________________________
# Execution
#_______________________________________________________________________________________


current = MnemonicEvent.new()

IO.foreach(logfile) {|x| 
	if (x["_______________________________________________________________________________________"])
		if (!isBadEvent(current))
			$events.push(current)
		else
			# puts "found unknown event #{current.mcpname}"
		end
		current = MnemonicEvent.new()
		# puts "_______________________________________________________________________________________"
	elsif (x["Wayside MCP"])
		comps = x.split(' ')
		mcpname = x.string_between_markers("(", ")")
		# puts "address is #{comps[2]} name is #{mcpname}"
		current.mcpname = mcpname if !mcpname.nil?
	elsif (x["Mnemonics"])
		ms = x.split('=')
		strs = ms[1].strip
		# puts "#{ms[1]}"
		current.mnemonics = strs
		s = strs.scan(/[\w'-]{3,}/)
		if (!($blockEvents & s).empty?)
			current.isOccupied = true
			puts "-----OCCUPIED #{s}"
		end

	elsif (matchDateStr(x))
		current.date = x.strip
	end 
}

# pp ($events)

$events.each do |e|
	if (e.isOccupied)
		puts "#{e.date} #{e.mcpname} occupied"
	end
end