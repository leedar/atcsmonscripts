#!/usr/bin/ruby

require 'pp'
require 'set'

#configuration
# logfile = "ATCSTestLog.txt"
# logfile = "ATCSTestLog.txt"
$verbose = false

#globals
$events = []
$blockEvents = ["BEAK", "BWAK", "BSAK", "BNAK", "BEGK", "BWGK", "BNGK", "BSGK","AOK"]

$oneChar = {
  "O" => "Occupancy",
  "B" => "Occupancy",
  "X" => "Out of Service",
  "T" => "Interlock Occupancy"
}

$twoChar = {
  "WA" => "West Approach Track",
  "EA" => "East Approach Track",
  "NA" => "North Approach Track",
  "SA" => "South Approach Track",
  "LA" => "Left Approach Track",
  "RA" => "Right Approach Track",
  "EG" => "Eastbound Proceed Signal",
  "WG" => "Westbound Proceed Signal",
  "NG" => "Northbound Proceed Signal",
  "SG" => "Soundbound Proceed Signal",
  "ST" => "Signal Stop Control",
  "NW" => "Normal Switch Alignment",
  "RW" => "Reverse Switch Alignment",
  "LZ" => "Switch Lock",
  "UL" => "Switch Unlocked"
}



#_______________________________________________________________________________________
# Functions
#_______________________________________________________________________________________

def numeric?(lookAhead)
  lookAhead =~ /[0-9]/
end

def letter?(lookAhead)
  lookAhead =~ /[A-Za-z]/
end

def matchDateStr(str) 
  regex = /\w{4}\/\d{2}\/\d{2}/
  if str =~ regex
     return true
  end
  return false
end 

def isBadEvent(event)
  return event.mcpname.eql?("none") || event.mnemonics.eql?("none") 
end

def tail_dash_f(filename)
  open(filename) do |file|
    file.read          
    case RUBY_PLATFORM   # string with OS name, like "amd64-freebsd8"
    when /bsd/, /darwin/
      require 'rb-kqueue'
      queue = KQueue::Queue.new     
      queue.watch_file(ARGV.first, :extend) do
        yield file.read             
      end
      queue.run                     
    when /linux/
      require 'rb-inotify'
      queue = INotify::Notifier.new  
      queue.watch(ARGV.first, :modify) do
        yield file.read             
      end
      queue.run                      
    else
      loop do           
        changes = file.read
        unless changes.empty?  
          yield changes
        end
        sleep 1.0       
      end
    end
  end
end


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
    ind = @mnemonics.split(",")
    eventStrings = []

    if ($verbose)
      ind.each { |m|
        cStr = ""
        if m.length == 4
          # track = (numeric?(m[0]) == nil) ? "?":  m[0]
          if (numeric?(m[0]) == nil) 
            track = $oneChar[m[0]]
          else
            track=m[0]
          end
          blocksignaltrack = "#{m[1]}#{m[2]}"
          typebit = m[3]
          if (track != nil)
            cStr="Track #{track} #{$twoChar[blocksignaltrack]}"
          else
            #assume block occupancy bit (B or O)
            cStr="Occupancy #{$twoChar[blocksignaltrack]}"
          end

        elsif m.length == 3
          cStr = m
        elsif m.length == 2
          cStr = m
        else
          puts "unhandled mnemonic #{m}"
        end
        eventStrings.push(cStr)
      }
    else
      bEvents = $blockEvents & ind
      if (!bEvents.empty?)
        bEvents.each { |m|
          blocksignaltrack = "#{m[1]}#{m[2]}"
          cStr="Occupancy #{$twoChar[blocksignaltrack]}"
          eventStrings.push(cStr)
        }
      end   
    end
    return eventStrings.to_s
  end

  def to_s
    attributes.each_with_object("") do |attribute, result|
      result << "#{attribute[1].to_s} "
    end
  end
end  

#_______________________________________________________________________________________
# Execution
#_______________________________________________________________________________________

p "parsing #{ARGV.first}"
current = MnemonicEvent.new()

tail_dash_f(ARGV.first) do |data|
  # puts "************************************ #{x}\n &&&&&&&&&&&&&&&&&&&&&&&&&&&"

  data.each_line do |x|
    if (x["_______________________________________________________________________________________"])
      if (!isBadEvent(current))
        puts "EVENT: #{current.date} #{current.mcpname} == #{current.eventString}"
        $events.push(current)
      else
        # puts "found bad event #{current.mcpname}"
      end
      current = MnemonicEvent.new()

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
        # puts "-----OCCUPIED #{s}"
      end

    elsif (matchDateStr(x))
      current.date = x.strip
    end 
  end

end



