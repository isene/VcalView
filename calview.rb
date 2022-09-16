#!/usr/bin/env ruby

# This is a simple script that takes vcal attachments and displays them in
# pure text. This is suitable for displaying callendar invitations in mutt.
# 
# Add this to your to your .mailcap:
# text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
#
# Created by Geir Isene <g@isene.com> in 2020 and released into Public Domain.

require "time"

# Sourced from https://stackoverflow.com/a/30795167
# Removed Rails mappings and resulting duplicates, picking somewhat arbitrary winners
windows_tz = {
"AUS Central Standard Time"=>"Australia/Darwin",
"AUS Eastern Standard Time"=>"Australia/Melbourne",
"Afghanistan Standard Time"=>"Asia/Kabul",
"Alaskan Standard Time"=>"America/Juneau",
"Arab Standard Time"=>"Asia/Kuwait",
"Arabian Standard Time"=>"Asia/Muscat",
"Arabic Standard Time"=>"Asia/Baghdad",
"Argentina Standard Time"=>"America/Argentina/Buenos_Aires",
"Atlantic Standard Time"=>"America/Halifax",
"Azerbaijan Standard Time"=>"Asia/Baku",
"Azores Standard Time"=>"Atlantic/Azores",
"Bahia Standard Time"=>"America/Bahia",
"Bangladesh Standard Time"=>"Asia/Dhaka",
"Belarus Standard Time"=>"Europe/Minsk",
"Canada Central Standard Time"=>"America/Regina",
"Cape Verde Standard Time"=>"Atlantic/Cape_Verde",
"Caucasus Standard Time"=>"Asia/Yerevan",
"Cen. Australia Standard Time"=>"Australia/Adelaide",
"Central America Standard Time"=>"America/Guatemala",
"Central Asia Standard Time"=>"Asia/Almaty",
"Central Brazilian Standard Time"=>"America/Cuiaba",
"Central Europe Standard Time"=>"Europe/Belgrade",
"Central European Standard Time"=>"Europe/Warsaw",
"Central Pacific Standard Time"=>"Pacific/Guadalcanal",
"Central Standard Time (Mexico)"=>"America/Mexico_City",
"Central Standard Time"=>"America/Chicago",
"China Standard Time"=>"Asia/Shanghai",
"Dateline Standard Time"=>"Etc/GMT+12",
"E. Africa Standard Time"=>"Africa/Nairobi",
"E. Australia Standard Time"=>"Australia/Brisbane",
"E. Europe Standard Time"=>"Etc/GMT-2",
"E. South America Standard Time"=>"America/Sao_Paulo",
"Eastern Standard Time (Mexico)"=>"America/Cancun",
"Eastern Standard Time"=>"America/New_York",
"Egypt Standard Time"=>"Africa/Cairo",
"Ekaterinburg Standard Time"=>"Asia/Yekaterinburg",
"FLE Standard Time"=>"Europe/Helsinki",
"Fiji Standard Time"=>"Pacific/Fiji",
"GMT Standard Time"=>"Etc/GMT",
"GTB Standard Time"=>"Europe/Bucharest",
"Georgian Standard Time"=>"Asia/Tbilisi",
"Greenland Standard Time"=>"America/Godthab",
"Greenwich Standard Time"=>"Etc/GMT",
"Hawaiian Standard Time"=>"Pacific/Honolulu",
"India Standard Time"=>"Asia/Kolkata",
"Iran Standard Time"=>"Asia/Tehran",
"Israel Standard Time"=>"Asia/Jerusalem",
"Jordan Standard Time"=>"Asia/Amman",
"Kaliningrad Standard Time"=>"Europe/Kaliningrad",
"Korea Standard Time"=>"Asia/Seoul",
"Libya Standard Time"=>"Africa/Tripoli",
"Line Islands Standard Time"=>"Pacific/Kiritimati",
"Magadan Standard Time"=>"Asia/Magadan",
"Mauritius Standard Time"=>"Indian/Mauritius",
"Middle East Standard Time"=>"Asia/Beirut",
"Montevideo Standard Time"=>"America/Montevideo",
"Morocco Standard Time"=>"Africa/Casablanca",
"Mountain Standard Time (Mexico)"=>"America/Mazatlan",
"Mountain Standard Time"=>"America/Denver",
"Myanmar Standard Time"=>"Asia/Rangoon",
"N. Central Asia Standard Time"=>"Asia/Novosibirsk",
"Namibia Standard Time"=>"Africa/Windhoek",
"Nepal Standard Time"=>"Asia/Kathmandu",
"New Zealand Standard Time"=>"Pacific/Auckland",
"Newfoundland Standard Time"=>"America/St_Johns",
"North Asia East Standard Time"=>"Asia/Irkutsk",
"North Asia Standard Time"=>"Asia/Krasnoyarsk",
"Pacific SA Standard Time"=>"America/Santiago",
"Pacific Standard Time (Mexico)"=>"America/Santa_Isabel",
"Pacific Standard Time"=>"America/Los_Angeles",
"Pakistan Standard Time"=>"Asia/Karachi",
"Paraguay Standard Time"=>"America/Asuncion",
"Romance Standard Time"=>"Europe/Paris",
"Russia Time Zone 10"=>"Asia/Srednekolymsk",
"Russia Time Zone 11"=>"Asia/Kamchatka",
"Russia Time Zone 3"=>"Europe/Samara",
"Russian Standard Time"=>"Europe/Moscow",
"SA Eastern Standard Time"=>"America/Cayenne",
"SA Pacific Standard Time"=>"America/Bogota",
"SA Western Standard Time"=>"America/Guyana",
"SE Asia Standard Time"=>"Asia/Bangkok",
"Samoa Standard Time"=>"Pacific/Apia",
"Singapore Standard Time"=>"Asia/Singapore",
"South Africa Standard Time"=>"Africa/Johannesburg",
"Sri Lanka Standard Time"=>"Asia/Colombo",
"Syria Standard Time"=>"Asia/Damascus",
"Taipei Standard Time"=>"Asia/Taipei",
"Tasmania Standard Time"=>"Australia/Hobart",
"Tokyo Standard Time"=>"Asia/Tokyo",
"Tonga Standard Time"=>"Pacific/Tongatapu",
"Turkey Standard Time"=>"Europe/Istanbul",
"US Eastern Standard Time"=>"America/Indiana/Indianapolis",
"US Mountain Standard Time"=>"America/Phoenix",
"UTC"=>"Etc/UTC",
"Ulaanbaatar Standard Time"=>"Asia/Ulaanbaatar",
"Venezuela Standard Time"=>"America/Caracas",
"Vladivostok Standard Time"=>"Asia/Vladivostok",
"W. Australia Standard Time"=>"Australia/Perth",
"W. Central Africa Standard Time"=>"Africa/Algiers",
"W. Europe Standard Time"=>"Europe/Berlin",
"West Asia Standard Time"=>"Asia/Tashkent",
"West Pacific Standard Time"=>"Pacific/Guam",
"Yakutsk Standard Time"=>"Asia/Yakutsk",
}

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
  stz = windows_tz[stz] or stz
  etz = windows_tz[etz] or etz
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
