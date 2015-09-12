#!/usr/bin/ruby

require 'pp'

#configuration
# mcpFile = "UP_SacramentoArea-20130713.mcp"
# mcpFile = "UP_Martinez+Niles-20150905.mcp"
mcpFile = ARGV.first

p "parsing #{mcpFile}"

#globals
$mcps = []


# class MCP
# 	def initialize(address = "none", name = "none") 
# 		@address = address 
# 		@name = name
# 	end

#   attr_reader :address, :name
#   attr_writer :address, :name

# 	def to_s
# 	  attributes.each_with_object("") do |attribute, result|
# 	    result << "#{attribute[1].to_s} "
# 	  end
# 	end
# end  

def dms_to_degrees(d, m, s)
  degrees = d
  fractional = m / 60 + s / 3600
  if d > 0
    degrees + fractional
  else
    degrees - fractional
  end
end

current = {:address => "", :name => "", :milepost => "", :controls => "", :indication => "", :subdivision => "", :statecounty => "", :longitude => 0, :latitude => 0}

IO.foreach(mcpFile) {|x| 
	if (x["MCPAddress"])
		current[:address] = x.split("=")[1].strip
		puts "MCPAddress is #{current[:address]}"
	elsif (x["MCPName"])
		current[:name] = x.split("=")[1].strip
		puts "MCPName is #{current[:name]}"
	elsif (x["MCPMilepost"])
		current[:milepost] = x.split("=")[1].strip
		puts "MCPMilepost is #{current[:milepost]}"
	elsif (x["MCPControlMnemonics"])
		current[:controls] = x.split("=")[1].strip
		puts "MCPControlMnemonics is #{current[:controls]}"
	elsif (x["MCPIndicationMnemonics"])
		current[:indication] = x.split("=")[1].strip
		puts "MCPIndicationMnemonics is #{current[:indication]}"
	elsif (x["MCPSubdivision"])
		current[:subdivision] = x.split("=")[1].strip
		puts "MCPSubdivision is #{current[:subdivision]}"
	elsif (x["MCPStateCounty"])
		current[:statecounty] = x.split("=")[1].strip
		puts "MCPStateCounty is #{current[:statecounty]}"
	elsif (x["MCPLongitude"])
		lg = x.split("=")[1].strip
		degrees=dms_to_degrees("#{lg[0]}#{lg[1]}#{lg[2]}".to_i, "#{lg[3]}#{lg[4]}".to_i, "#{lg[5]}#{lg[6]}".to_i)
		current[:longitude] = degrees
		# current[:longitude] = x.split("=")[1].strip
		puts "MCPLongitude is #{current[:longitude]} str = #{lg}"
	elsif (x["MCPLatitude"])
		lat = x.split("=")[1].strip
		# current[:latitude] = x.split("=")[1].strip
		degrees=dms_to_degrees("#{lat[0]}#{lat[1]}".to_i, "#{lat[2]}#{lat[3]}".to_i, "#{lat[4]}#{lat[5]}".to_i)
		current[:latitude] = degrees
		puts "MCPLatitude is #{current[:latitude]}   str = #{lat}"
		$mcps.push(current)
		current = {:address => "", :name => "", :controls => "", :indication => "", :subdivision => "", :statecounty => "", :longitude => 0, :latitude => 0}
	end 
}

pp ($mcps)