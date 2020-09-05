#!/usr/bin/env ruby

# This is a simple script that takes vcal attachments and displays them in
# pure text. This is suitable for displaying callendar invitations in mutt.
# 
# Add this to your to your .mailcap:
# text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
#
# Created by Geir Isene <g@isene.com> in 2020 and released into Public Domain.

class String
  def colorize(color_code) # This is for general terminal output - doesn't work inside mutt
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end
  def green
    colorize(32)
  end
  def yellow
    colorize(33)
  end
  def blue
    colorize(34)
  end
end

vcal  = ARGF.read

if vcal.match( /^DTSTART;TZID/ ) # Newer vcal
  # Get the dates
  sdate = vcal[ /^DTSTART;TZID=.*:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND;TZID=.*:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  # Get the times
  stime = vcal[ /^DTSTART;TZID=.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  etime = vcal[ /^DTEND;TZID=.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  # Get organizer
  org   = vcal[ /^ORGANIZER;CN=(.*)/, 1 ].sub( /:mailto:/, ' <') + ">"
  # Get description
  desc  = vcal[ /^DESCRIPTION;.*?:(.*)^UID/m, 1 ].gsub( /\n /, '' ).gsub( /\\n/, "\n" ).gsub( /\n\n+/, "\n" ).gsub( / \| /, "\n" ).sub( /^\n/, '' )
else                    # Older vcal
  # Get the dates
  sdate = vcal[ /^DTSTART:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  # Get the times
  stime = vcal[ /^DTSTART.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  etime = vcal[ /^DTEND.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  # Get organizer
  org   = vcal[ /^ORGANIZER:(.*)/, 1 ].sub( /MAILTO:/, ' <') + ">"
  # Get description
  desc  = vcal[ /^DESCRIPTION:(.*)^SUMMARY/m, 1 ].gsub( /\n /, '' ).gsub( /\\n/, "\n" ).gsub( /\n\n+/, "\n" ).gsub( / \| /, "\n" ).sub( /^\n/, '' )
end

sdate == edate ? dates = sdate : dates = sdate + " - " + edate
stime == etime ? times = stime : times = stime + " - " + etime
# Get participants
part  = vcal.scan( /^ATTENDEE.*CN=([\s\S]*?@.*)\n/ ).join('%').gsub( /\n /, '').gsub( /%/, ">\n   " ).gsub( /:mailto:/, " <" )
part  = "   " + part + ">" if part != ""
# Get summary and description
sum   = vcal[ /^SUMMARY;.*:(.*)/, 1 ]
sum   = vcal[ /^SUMMARY:(.*)/, 1 ] if sum == nil

# Print the result in a tidy fashion
puts "WHAT: " + (sum).yellow
puts "WHEN: " + (dates + ", " + times).green
puts ""
puts "ORGANIZER: " + org
puts "PARTICIPANTS:", part
puts ""
puts "DESCRIPTION:", desc
