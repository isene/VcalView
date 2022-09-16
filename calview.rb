#!/usr/bin/env ruby

# This is a simple script that takes vcal attachments and displays them in
# pure text. This is suitable for displaying callendar invitations in mutt.
# 
# Add this to your to your .mailcap:
# text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
#
# Created by Geir Isene <g@isene.com> in 2020 and released into Public Domain.

require "time"

vcal  = ARGF.read

# Fix multiline participants
vcal.gsub!( /(^ATTENDEE.*)\n^ (.*)/, '\1\2' )

# Get dates and times
if vcal.match( /^DTSTART;TZID=/ )
  require "tzinfo"
  sdate = vcal[ /^DTSTART;TZID=.*:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND;TZID=.*:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  stime = vcal[ /^DTSTART;TZID=.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  etime = vcal[ /^DTEND;TZID=.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  stz = vcal[ /^DTSTART;TZID=(.*):/, 1 ]
  etz = vcal[ /^DTEND;TZID=(.*):/, 1 ]
  stz = TZInfo::Timezone.get(stz)
  etz = TZInfo::Timezone.get(etz)
elsif vcal.match( /DTSTART;VALUE=DATE:/ )
  sdate = vcal[ /^DTSTART;VALUE=DATE:(.*)/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND;VALUE=DATE:(.*)/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  begin
    stime = vcal[ /^DTSTART.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  rescue
    stime = "All day"
  end
  begin
    etime = vcal[ /^DTEND.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  rescue
    etime = stime
  end
  stz = nil
  etz = nil
else
  sdate = vcal[ /^DTSTART:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  edate = vcal[ /^DTEND:(.*)T/, 1 ].sub( /(\d\d\d\d)(\d\d)(\d\d)/, '\1-\2-\3') 
  stime = vcal[ /^DTSTART.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  etime = vcal[ /^DTEND.*T(\d\d\d\d)/, 1 ].sub( /(\d\d)(\d\d)/, '\1:\2')
  stz = nil
  etz = nil
end

# Adjust for local TZ offset
unless vcal.match( /^TZOFFSET/ )
  stime = (stime.to_i + Time.now.getlocal.utc_offset / 3600).to_s + stime.sub( /\d\d/, '') unless stime == "All day"
  etime = (etime.to_i + Time.now.getlocal.utc_offset / 3600).to_s + etime.sub( /\d\d/, '') unless stime == "All day"
end

# Get organizer
if vcal.match( /^ORGANIZER;CN=/ )
  org   = vcal[ /^ORGANIZER;CN=(.*)/, 1 ].sub( /:mailto:/i, ' <') + ">"
else
  begin
    org = vcal[ /^ORGANIZER:(.*)/, 1 ].sub( /MAILTO:/i, ' <') + ">"
  rescue
    org = "(None set)"
  end
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

if stz then stime = stz.local_to_utc(Time.parse(sdate + " " + stime)); stime = stime.localtime end
if etz then etime = etz.local_to_utc(Time.parse(edate + " " + etime)); etime = etime.localtime end

sdate == edate ? dates = sdate : dates = sdate + " - " + edate
dobj = Time.parse( sdate )
wday = dobj.strftime('%A')
week = dobj.strftime('%-V')
stime == etime ? times = stime : times = stime.strftime("%H:%M") + " - " + etime.strftime("%H:%M")
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
