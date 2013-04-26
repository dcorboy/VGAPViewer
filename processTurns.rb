#!/usr/bin/env ruby

#	processTurns.rb
#	This script processes locally-stored JSON files into a scene file that is rendered
#	by the VGAPViewer web page.
#
#	Copyright 2013 Dave Corboy
#
#	This file is part of VGAPViewer.
#
#	VGAPViewer is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	VGAPViewer is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	If you did not receive a copy of the GNU General Public License
#	along with VGAPViewer, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'json'
require 'pp'
require 'optparse'
include Math

# Input file constants
MSG_STARBASE = 11
MSG_COMBAT = 6

options = {}
optparse = OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"

	# Mandatory argument.
	opts.on("-fMANDTORY", "--file FILE.ext",
              "Required root name of sequential FILEXX.ext turn files") do |f|
        options[:file] = f
    end
    
	opts.on("-sMANDTORY", "--start STARTTURN",
              "Required first turn number to process") do |s|
        options[:start] = s
    end

	opts.on("-eMANDTORY", "--end ENDTURN",
              "Required end turn number to process") do |e|
        options[:end] = e
    end

	opts.separator ""
    opts.separator "Specific options:"

	opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
		options[:verbose] = v
	end

	opts.on_tail("-h", "--help", "Show this message") do
		puts opts
		exit
	end
end

begin
	optparse.parse!
	mandatory = [:file, :start, :end]								# Enforce the presence of
	missing = mandatory.select{ |param| options[param].nil? }		# the -fileroot option (can be [:from, :to])
	if not missing.empty?
		puts "Missing options: #{missing.join(', ')}"
		puts optparse
		exit
	end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument	# Friendly output when parsing fails
	puts $!.to_s
	puts optparse
	exit
end

if (options[:verbose] == true)
	p options
	p ARGV
end

class VGAPParser
@@jitter_array = [[1, 0], [-0.7, -0.7], [0, 1], [0.7, -0.7], [-1, 0], [0.7, 0.7], [0, -1], [-0.7, 0.7]]

	def initialize(options)
		@options = options
		@output = Hash.new {|h,k| h[k] = []}
		@jitter_count = 0
	end

	# Functions
	def nickel_jitter(x, y)

		rscale = 5 * (rand(3) + 1)	# 5, 10 or 15 for a scaling factor triples our jitter options
		jx = x + (@@jitter_array[@jitter_count % 8][0] * rscale).to_i
		jy = y + (@@jitter_array[@jitter_count % 8][1] * rscale).to_i

		if (@options[:verbose] == true)
			puts "jitter"
			puts "begin - x: #{x}\ty: #{y}"
			puts "  end - x: #{jx}\ty: #{jy}"
			puts "   rscale: #{rscale}"
		end

		@jitter_count += 1
		return jx, jy
	end

	def speed_limit(x, y, targetx, targety, warp)
		dx = targetx - x
		dy = targety - y
		if ( dx != 0 || dy != 0 )
			scale = warp**2 / sqrt(dx**2 + dy**2)
			if (scale > 1.0)
				scale = 1.0
			end
		else
			scale = 1.0
		end
		#puts "#{x}\t#{y}\t#{targetx}\t#{targety}\t#{warp}"
		#puts "#{scale}\t#{x + (dx * scale)}\t#{y + (dy * scale)}"
		return (x + (dx * scale)).to_i, (y + (dy * scale)).to_i
	end

	# parse
	# this is the main routine which parses the options and loads each turn file
	# and invokes the turn parsers
	def parse
		fileroot = File.dirname(@options[:file]) + "/" + File.basename(@options[:file], '.*')
		fileext = File.extname(@options[:file])	

		for i in @options[:start]..@options[:end] do			# process each turn file
			if (@options[:verbose] == true)
				puts "#{fileroot}#{i}#{fileext}"
			end

			json = File.read("#{fileroot}#{i}#{fileext}")
			turnhash = JSON.parse(json)
	
			if (i == @options[:start])
				parseControl(turnhash)
			end

			parseShipsTurn(turnhash)
			parseMessagesTurn(turnhash)
			parseMinefieldsTurn(turnhash)

		end		# process each turn

		return @output

	end # parse

	def parseControl(turn)
		control = Hash.new
		@output[:control] = control

		@player_id = turn['rst']['player']['id']		# set to the POV player's ID to filter in/out data
		control[:type] = :singleplayer
		control[:firstturn] = turn['rst']['settings']['turn']
		control[:turns] = @options[:end].to_i - @options[:start].to_i + 1
		control[:name] = turn['rst']['settings']['name']
		control[:playerid] = turn['rst']['player']['id']
		control[:playername] = turn['rst']['player']['username']
		control[:background] = turn['rst']['maps'][0]
	end

	# Process ships section
	#   Ship movement
	def parseShipsTurn(turn)

		ships = turn['rst']['ships']

		if (@options[:verbose] == true)
			puts "Processing Turn: #{turn['rst']['settings']['turn']}"
			puts "Player ID: #{@player_id}"
			puts "Total Ships: #{ships.length}"
		end

		shipmoves = Array.new

		ships.each do |ship|
			if (ship['ownerid'] == @player_id)
				shipmove = Hash.new
				shipmove[:x] = ship['x']
				shipmove[:y] = ship['y']
				shipmove[:targetx], shipmove[:targety] = speed_limit(ship['x'], ship['y'], ship['targetx'], ship['targety'], ship['warp'])
				shipmoves << shipmove
			end
		end

		@output[:movement] << shipmoves

	end	# parseShipsTurn

	# Process messages section
	#   Ship builds
	#   Starbase builds
	#   Ships destroyed
	#   Enemies destroyed
	def parseMessagesTurn(turn)

		messages = turn['rst']['messages']

		if (@options[:verbose] == true)
			puts "Total Messages: #{messages.length}"
		end

		turnshipbuilds = Array.new
		turnstarbasebuilds = Array.new
		turnshipsdestroyed = Array.new
		turnenemiesdestroyed = Array.new

		messages.each do |message|
			body = message['body']

			if (message['messagetype'] == MSG_STARBASE && message['ownerid'] == @player_id)
				if (body =~ /new starbase has been constructed/)
					build = Hash.new
					build[:x] = message['x']
					build[:y] = message['y']
					turnstarbasebuilds << build
				elsif (body =~ /has been constructed/)
					build = Hash.new
					build[:x] = message['x']
					build[:y] = message['y']
					turnshipbuilds << build
				end
			end

			if (message['messagetype'] == MSG_COMBAT) # && message['ownerid'] == @player_id)
				if (body =~ /has destroyed/)
					boom = Hash.new
					x, y  = nickel_jitter(message['x'], message['y'])
					boom[:x] = x
					boom[:y] = y
					turnenemiesdestroyed << boom
				elsif (body =~ /has been destroyed/)
					boom = Hash.new
					x, y  = nickel_jitter(message['x'], message['y'])
					boom[:x] = x
					boom[:y] = y
					turnshipsdestroyed << boom
				end
			end
		end	# each message

		@output[:shipbuilds] << turnshipbuilds
		@output[:starbasebuilds] << turnstarbasebuilds
		@output[:shipsdestroyed] << turnshipsdestroyed
		@output[:enemiesdestroyed] << turnenemiesdestroyed

	end # parseMessagesTurn

	# Process minefields section
	#   Minefields
	def parseMinefieldsTurn(turn)

		fileminefields = turn['rst']['minefields']

		if (@options[:verbose] == true)
			puts "Total Minefields: #{fileminefields.length}"
		end

		turnminefields = Array.new
		currentminefieldsindex = Array.new

		if (@historicalminefieldsindex == nil)
			@historicalminefieldsindex = Array.new		# this will hold any info we have about pre-existing minefields
		end

		fileminefields.each do |fileminefield|
			turnminefield = Hash.new

			turnminefield[:x] = fileminefield['x']
			turnminefield[:y] = fileminefield['y']
			turnminefield[:ownerid] = fileminefield['ownerid']
			turnminefield[:radius] = fileminefield['radius']

			id = fileminefield['id']
			currentminefieldsindex[id] = turnminefield	# store this minefield in the indexed turn record

			if (@historicalminefieldsindex[id] != nil)
				turnminefield[:oldradius] = @historicalminefieldsindex[id][:radius]
				@historicalminefieldsindex[id] = nil		# once accounted for, remove field from the record
			else
				turnminefield[:oldradius] = 0
			end

			turnminefields << turnminefield

		end

		# and any fields remaining in the historical record should be displayed as shrinking to zero
		@historicalminefieldsindex.compact.each do |oldminefield|
			turnminefield = Hash.new

			turnminefield[:x] = oldminefield[:x]
			turnminefield[:y] = oldminefield[:y]
			turnminefield[:ownerid] = oldminefield[:ownerid]
			turnminefield[:oldradius] = oldminefield[:radius]
			turnminefield[:radius] = 0
	
			turnminefields << turnminefield
		end

		if (@options[:verbose] == true)
			puts "Recouped #{@historicalminefieldsindex.compact.length} minefields"
		end

		@historicalminefieldsindex = currentminefieldsindex
		@output[:minefields] << turnminefields

	end	# parseMinefieldsTurn

end		# class VGAPParser

p = VGAPParser.new(options)
output = p.parse

if (options[:verbose] == true)
	pp output[:control]
elsif
	puts "sceneJSON = #{output.to_json};"
end


