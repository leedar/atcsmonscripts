#!/usr/bin/ruby

require 'pp'

#configuration
# mcpFile = "UP_SacramentoArea-20130713.mcp"
# mcpFile = "UP_Martinez+Niles-20150905.mcp"
mcpFile = ARGV.first
$verbose  = (ARGV[1] == "-v")

p "parsing #{mcpFile}"

#globals
$mcps = []

def log(str)
	if ($verbose) 
		puts str
	end
end

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

  # log ("degrees: #{d}, minutes: #{m}, seconds: #{s}")
  degrees = d.to_f
  fractional = m.to_f/ 60 + s.to_f / 3600
  if d > 0
    degrees + fractional.to_f
  else
    degrees - fractional.to_f
  end
end

current = {:address => "", :name => "", :milepost => "", :controls => "", :indication => "", :subdivision => "", :statecounty => "", :longitude => 0, :latitude => 0}

IO.foreach(mcpFile) {|x| 
	if (x["MCPAddress"])
		current[:address] = x.split("=")[1].strip
		log ("MCPAddress is #{current[:address]}")
	elsif (x["MCPName"])
		current[:name] = x.split("=")[1].strip
		log ("MCPName is #{current[:name]}")
	elsif (x["MCPMilepost"])
		current[:milepost] = x.split("=")[1].strip
		log ("MCPMilepost is #{current[:milepost]}")
	elsif (x["MCPControlMnemonics"])
		current[:controls] = x.split("=")[1].strip
		log ("MCPControlMnemonics is #{current[:controls]}")
	elsif (x["MCPIndicationMnemonics"])
		current[:indication] = x.split("=")[1].strip
		log ("MCPIndicationMnemonics is #{current[:indication]}")
	elsif (x["MCPSubdivision"])
		current[:subdivision] = x.split("=")[1].strip
		log ("MCPSubdivision is #{current[:subdivision]}")
	elsif (x["MCPStateCounty"])
		current[:statecounty] = x.split("=")[1].strip
		log ("MCPStateCounty is #{current[:statecounty]}")
	elsif (x["MCPLongitude"])
		lg = x.split("=")[1].strip
		if (lg[7] == "W")
			degrees=dms_to_degrees("-#{lg[0]}#{lg[1]}#{lg[2]}".to_i, "#{lg[3]}#{lg[4]}".to_i, "#{lg[5]}#{lg[6]}".to_i)
		else 
			degrees=dms_to_degrees("#{lg[0]}#{lg[1]}#{lg[2]}".to_i, "#{lg[3]}#{lg[4]}".to_i, "#{lg[5]}#{lg[6]}".to_i)
		end
		current[:longitude] = degrees
		# current[:longitude] = x.split("=")[1].strip
		log ("MCPLongitude is #{current[:longitude]} str = #{lg}")
	elsif (x["MCPLatitude"])
		lat = x.split("=")[1].strip
		# current[:latitude] = x.split("=")[1].strip
		if (lat[6] == "N")
			degrees=dms_to_degrees("#{lat[0]}#{lat[1]}".to_i, "#{lat[2]}#{lat[3]}".to_i, "#{lat[4]}#{lat[5]}".to_i)
		else
			degrees=dms_to_degrees("-#{lat[0]}#{lat[1]}".to_i, "#{lat[2]}#{lat[3]}".to_i, "#{lat[4]}#{lat[5]}".to_i)
		end

		current[:latitude] = degrees
		log ("MCPLatitude is #{current[:latitude]}   str = #{lat}")
		$mcps.push(current)
		current = {:address => "", :name => "", :controls => "", :indication => "", :subdivision => "", :statecounty => "", :longitude => 0, :latitude => 0}
	end 
}

pp ($mcps)