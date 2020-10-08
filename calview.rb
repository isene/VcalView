#!/usr/bin/env ruby

# This is a simple script that takes vcal attachments and displays them in
# pure text. This is suitable for displaying callendar invitations in mutt.
# 
# Add this to your to your .mailcap:
# text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
#
# Created by Geir Isene <g@isene.com> in 2020 and released into Public Domain.

require "date"

vcal  = ARGF.read

# Get dates and times
if vcal.match( /^DTSTART;TZID=/ )
  sdate = vcal[ /^DTSTART;TZID=.*:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND;TZID=.*:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  stime = vcal[ /^DTSTART;TZID=.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  etime = vcal[ /^DTEND;TZID=.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
elsif vcal.match( /DTSTART;VALUE=DATE:/ )
  sdate = vcal[ /^DTSTART;VALUE=DATE:(.*)/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND;VALUE=DATE:(.*)/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  stime = vcal[ /^DTSTART.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  begin
    etime = vcal[ /^DTEND.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  rescue
    etime = stime
  end
else
  sdate = vcal[ /^DTSTART:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  stime = vcal[ /^DTSTART.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  etime = vcal[ /^DTEND.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
end

# Get organizer
if vcal.match( /^ORGANIZER;CN=/ )
  org   = vcal[ /^ORGANIZER;CN=(.*)/, 1 ].sub( /:mailto:/i, ' <') + ">"
else
  org   = vcal[ /^ORGANIZER:(.*)/, 1 ].sub( /MAILTO:/i, ' <') + ">"
end

# Get description
if vcal.match( /^DESCRIPTION;.*?:(.*)^UID/m )
  desc  = vcal[ /^DESCRIPTION;.*?:(.*)^UID/m, 1 ].gsub( /\n /, '' ).gsub( /\\n/, "\n" ).gsub( /\n\n+/, "\n" ).gsub( / \| /, "\n" ).sub( /^\n/, '' )
else
  begin
    desc  = vcal[ /^DESCRIPTION:(.*)^SUMMARY/m, 1 ].gsub( /\n /, '' ).gsub( /\\n/, "\n" ).gsub( /\n\n+/, "\n" ).gsub( / \| /, "\n" ).sub( /^\n/, '' )
  rescue
    desc  = ""
  end
end

sdate == edate ? dates = sdate : dates = sdate + " - " + edate
dobj = DateTime.parse( sdate )
wday = dobj.strftime('%A')
week = dobj.strftime('%-V')
stime == etime ? times = stime : times = stime + " - " + etime
# Get participants
part  = vcal.scan( /^ATTENDEE.*CN=([\s\S]*?@.*)\n/ ).join('%').gsub( /\n /, '').gsub( /%/, ">\n   " ).gsub( /:mailto:/i, " <" )
part  = "   " + part + ">" if part != ""
# Get summary and description
sum   = vcal[ /^SUMMARY;.*:(.*)/, 1 ]
sum   = vcal[ /^SUMMARY:(.*)/, 1 ] if sum == nil

# Print the result in a tidy fashion
puts "WHAT: " + (sum)
puts "WHEN: " + (dates + " (" + wday + " of week " + week + "), " + times)
puts ""
puts "ORGANIZER: " + org
puts "PARTICIPANTS:", part
puts ""
puts "DESCRIPTION:", desc
