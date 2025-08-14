#!/usr/bin/env ruby

# VcalView - A simple VCAL/ICS viewer for terminal and mutt
# 
# Add this to your .mailcap:
# text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
#
# Created by Geir Isene <g@isene.com> in 2020 and released into Public Domain.

require "time"
require "optparse"
require "strscan"

class VcalParser
  # Precompile all regex patterns for better performance
  PATTERNS = {
    multiline_attendee: /(^ATTENDEE.*)\n^ (.*)/,
    dtstart_tzid: /^DTSTART;TZID=(.*?):(.*?)(?:T(\d{6}))?$/,
    dtend_tzid: /^DTEND;TZID=(.*?):(.*?)(?:T(\d{6}))?$/,
    dtstart_date: /^DTSTART;VALUE=DATE:(.*)$/,
    dtend_date: /^DTEND;VALUE=DATE:(.*)$/,
    dtstart_utc: /^DTSTART:(.*?)(?:T(\d{6}))?$/,
    dtend_utc: /^DTEND:(.*?)(?:T(\d{6}))?$/,
    organizer_cn: /^ORGANIZER;CN=(.*)$/,
    organizer: /^ORGANIZER:(.*)$/,
    attendee: /^ATTENDEE.*CN=([\s\S]*?@.*)\n/,
    summary_param: /^SUMMARY;.*:(.*)$/,
    summary: /^SUMMARY:(.*)$/,
    description_uid: /^DESCRIPTION;.*?:(.*)^UID/m,
    description_summary: /^DESCRIPTION:(.*)^SUMMARY/m,
    description_generic: /^DESCRIPTION:(.*?)^[A-Z]/m,
    location: /^LOCATION:(.*)$/,
    uid: /^UID:(.*)$/,
    rrule: /^RRULE:(.*)$/,
    status: /^STATUS:(.*)$/,
    priority: /^PRIORITY:(.*)$/,
    tzoffset: /^TZOFFSET/,
    date_format: /(\d{4})(\d{2})(\d{2})/,
    time_format: /(\d{2})(\d{2})/,
    begin_vcal: /BEGIN:VCALENDAR/,
    begin_event: /BEGIN:VEVENT/
  }.freeze

  # Windows timezone mappings - only loaded when needed
  WINDOWS_TZ = {
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
  }.freeze

  def initialize(vcal_content)
    @vcal = vcal_content
    @event = {}
    @tzinfo_loaded = false
  end

  def parse
    return nil unless valid_vcal?
    
    # Fix multiline participants (single gsub operation)
    @vcal.gsub!(PATTERNS[:multiline_attendee], '\1\2')
    
    # Parse in most likely order of appearance
    parse_summary
    parse_dates_and_times
    parse_organizer
    parse_location
    parse_description
    parse_participants
    parse_uid
    parse_recurrence
    parse_status
    parse_priority
    
    @event
  end

  private

  def valid_vcal?
    return false if @vcal.nil? || @vcal.empty?
    return false unless @vcal.match?(PATTERNS[:begin_vcal]) || @vcal.match?(PATTERNS[:begin_event])
    true
  end

  def load_tzinfo
    return if @tzinfo_loaded
    begin
      require "tzinfo"
      @tzinfo_loaded = true
    rescue LoadError
      @tzinfo_loaded = false
    end
  end

  def parse_dates_and_times
    # Check for timezone dates first (most complex)
    if match = @vcal.match(PATTERNS[:dtstart_tzid])
      parse_timezone_dates_fast(match)
    elsif match = @vcal.match(PATTERNS[:dtstart_date])
      parse_all_day_dates_fast(match)
    else
      parse_utc_dates_fast
    end
  end

  def parse_timezone_dates_fast(start_match)
    load_tzinfo
    
    stz_name = start_match[1]
    sdate = extract_date(start_match[2])
    stime = start_match[3] ? extract_time(start_match[3]) : nil
    
    end_match = @vcal.match(PATTERNS[:dtend_tzid])
    if end_match
      etz_name = end_match[1]
      edate = extract_date(end_match[2])
      etime = end_match[3] ? extract_time(end_match[3]) : nil
    else
      etz_name = stz_name
      edate = sdate
      etime = stime
    end
    
    if @tzinfo_loaded && stime && etime
      stz = convert_timezone(stz_name)
      etz = convert_timezone(etz_name)
      
      if stz && etz
        begin
          stime = stz.local_to_utc(Time.parse("#{sdate} #{stime}")).localtime
          etime = etz.local_to_utc(Time.parse("#{edate} #{etime}")).localtime
        rescue
          # Keep string times on error
        end
      end
    end
    
    store_date_time_info(sdate, edate, stime, etime)
  end

  def parse_all_day_dates_fast(start_match)
    sdate = extract_date(start_match[1])
    
    end_match = @vcal.match(PATTERNS[:dtend_date])
    edate = end_match ? extract_date(end_match[1]) : sdate
    
    store_date_time_info(sdate, edate, "All day", "All day")
  end

  def parse_utc_dates_fast
    start_match = @vcal.match(PATTERNS[:dtstart_utc])
    return unless start_match
    
    sdate = extract_date(start_match[1])
    stime = start_match[2] ? extract_time(start_match[2]) : nil
    
    end_match = @vcal.match(PATTERNS[:dtend_utc])
    if end_match
      edate = extract_date(end_match[1])
      etime = end_match[2] ? extract_time(end_match[2]) : nil
    else
      edate = sdate
      etime = stime
    end
    
    # Adjust for local TZ offset if no TZOFFSET specified
    unless @vcal.match?(PATTERNS[:tzoffset]) || stime == "All day"
      offset = Time.now.getlocal.utc_offset / 3600
      stime = adjust_time_with_offset(stime, offset) if stime
      etime = adjust_time_with_offset(etime, offset) if etime
    end
    
    store_date_time_info(sdate, edate, stime, etime)
  end

  def extract_date(date_str)
    return nil unless date_str
    # Direct string manipulation is faster than regex for fixed format
    return date_str if date_str.include?('-')
    "#{date_str[0,4]}-#{date_str[4,2]}-#{date_str[6,2]}"
  end

  def extract_time(time_str)
    return nil unless time_str
    # Direct string manipulation is faster than regex for fixed format
    # Handle both 4-digit (HHMM) and 6-digit (HHMMSS) formats
    "#{time_str[0,2]}:#{time_str[2,2]}"
  end

  def adjust_time_with_offset(time_str, offset)
    return time_str unless time_str && time_str[2] == ':'
    hour = time_str[0,2].to_i + offset
    "#{hour}:#{time_str[3,2]}"
  end

  def convert_timezone(tz_name)
    return nil unless tz_name && @tzinfo_loaded
    
    # Check for Windows timezone mapping
    tz_name = WINDOWS_TZ[tz_name] || tz_name
    
    begin
      TZInfo::Timezone.get(tz_name)
    rescue
      nil
    end
  end

  def store_date_time_info(sdate, edate, stime, etime)
    @event[:start_date] = sdate
    @event[:end_date] = edate
    @event[:dates] = sdate == edate ? sdate : "#{sdate} - #{edate}"
    
    if sdate
      begin
        dobj = Time.parse(sdate)
        @event[:weekday] = dobj.strftime('%A')
        @event[:week] = dobj.strftime('%-V')
      rescue
        # Skip weekday/week on parse error
      end
    end
    
    if stime.is_a?(Time) && etime.is_a?(Time)
      @event[:times] = stime == etime ? stime.strftime("%H:%M") : "#{stime.strftime("%H:%M")} - #{etime.strftime("%H:%M")}"
    elsif stime == "All day"
      @event[:times] = "All day"
    else
      @event[:times] = stime == etime || stime == stime.to_s ? stime : "#{stime} - #{etime}"
    end
  end

  def parse_organizer
    if match = @vcal.match(PATTERNS[:organizer_cn])
      org = match[1].sub(/:mailto:/i, ' <') + ">"
    elsif match = @vcal.match(PATTERNS[:organizer])
      org = match[1].sub(/MAILTO:/i, '<') + ">"
    else
      org = "(None set)"
    end
    @event[:organizer] = org
  end

  def parse_participants
    participants = @vcal.scan(PATTERNS[:attendee])
    if participants.any?
      # Use join with newline directly instead of multiple gsubs
      part = participants.flatten
        .map { |p| p.gsub(/\n /, '').sub(/:mailto:/i, " <") + ">" }
        .join("\n   ")
      @event[:participants] = "   #{part}"
    else
      @event[:participants] = ""
    end
  end

  def parse_summary
    match = @vcal.match(PATTERNS[:summary_param]) || @vcal.match(PATTERNS[:summary])
    @event[:summary] = clean_text(match[1]) if match
  end

  def parse_description
    match = @vcal.match(PATTERNS[:description_uid]) ||
            @vcal.match(PATTERNS[:description_summary]) ||
            @vcal.match(PATTERNS[:description_generic])
    
    if match
      desc = match[1]
        .gsub(/\n /, '')
        .gsub(/\\n/, "\n")
        .gsub(/\n\n+/, "\n")
        .gsub(/ \| /, "\n")
        .strip
      @event[:description] = desc
    else
      @event[:description] = ""
    end
  end

  def parse_location
    match = @vcal.match(PATTERNS[:location])
    @event[:location] = clean_text(match[1]) if match
  end

  def parse_uid
    match = @vcal.match(PATTERNS[:uid])
    @event[:uid] = match[1].strip if match
  end

  def parse_recurrence
    # Only look for RRULE within the VEVENT section
    vevent_section = @vcal[/BEGIN:VEVENT.*?END:VEVENT/m]
    return unless vevent_section
    
    match = vevent_section.match(PATTERNS[:rrule])
    @event[:recurrence] = parse_rrule(match[1]) if match
  end

  def parse_rrule(rrule)
    # Use StringScanner for faster parsing
    parts = {}
    rrule.split(';').each do |part|
      key, value = part.split('=', 2)
      parts[key] = value
    end
    
    freq = parts['FREQ']
    interval = parts['INTERVAL'] || '1'
    count = parts['COUNT']
    until_date = parts['UNTIL']
    
    recurrence = case freq
    when 'DAILY'
      interval == '1' ? 'Daily' : "Every #{interval} days"
    when 'WEEKLY'
      interval == '1' ? 'Weekly' : "Every #{interval} weeks"
    when 'MONTHLY'
      interval == '1' ? 'Monthly' : "Every #{interval} months"
    when 'YEARLY'
      interval == '1' ? 'Yearly' : "Every #{interval} years"
    else
      freq
    end
    
    recurrence += " (#{count} times)" if count
    recurrence += " (until #{extract_date(until_date)})" if until_date
    
    recurrence
  end

  def parse_status
    match = @vcal.match(PATTERNS[:status])
    @event[:status] = match[1].strip.capitalize if match
  end

  def parse_priority
    match = @vcal.match(PATTERNS[:priority])
    if match
      priority = match[1].strip
      @event[:priority] = case priority
      when '1', '2' then 'High'
      when '3', '4', '5' then 'Normal'
      when '6', '7', '8', '9' then 'Low'
      else priority
      end
    end
  end

  def clean_text(text)
    return nil unless text
    text.gsub(/\n /, '').gsub(/\\n/, "\n").strip
  end
end

class CalendarViewer
  def initialize(options = {})
    @format = options[:format] || :text
    @verbose = options[:verbose] || false
  end

  def display(event)
    return puts "Error: Invalid or empty calendar file" unless event
    
    case @format
    when :json
      display_json(event)
    when :compact
      display_compact(event)
    else
      display_text(event)
    end
  end

  private

  def display_text(event)
    # Build output string first, then print once
    output = []
    
    output << "WHAT: #{event[:summary]}" if event[:summary]
    
    if event[:dates]
      time_info = event[:dates]
      time_info += " (#{event[:weekday]} of week #{event[:week]})" if event[:weekday] && event[:week]
      time_info += ", #{event[:times]}" if event[:times]
      output << "WHEN: #{time_info}"
    end
    
    output << "WHERE: #{event[:location]}" if event[:location] && !event[:location].empty?
    output << "RECURRENCE: #{event[:recurrence]}" if event[:recurrence]
    output << "STATUS: #{event[:status]}" if event[:status]
    output << "PRIORITY: #{event[:priority]}" if event[:priority]
    
    output << ""
    output << "ORGANIZER: #{event[:organizer]}" if event[:organizer]
    
    if event[:participants] && !event[:participants].empty?
      output << "PARTICIPANTS:"
      output << event[:participants]
    end
    
    if event[:description] && !event[:description].empty?
      output << ""
      output << "DESCRIPTION:"
      output << event[:description]
    end
    
    if @verbose && event[:uid]
      output << ""
      output << "UID: #{event[:uid]}"
    end
    
    puts output.join("\n")
  end

  def display_compact(event)
    output = []
    output << "#{event[:summary]} | #{event[:dates]} #{event[:times]}"
    output << "Location: #{event[:location]}" if event[:location]
    output << "Organizer: #{event[:organizer]}" if event[:organizer]
    puts output.join("\n")
  end

  def display_json(event)
    require 'json'
    puts JSON.pretty_generate(event)
  end
end

# Main execution
if __FILE__ == $0
  options = {}
  
  OptionParser.new do |opts|
    opts.banner = "Usage: calview.rb [options] [file]"
    
    opts.on("-f", "--format FORMAT", [:text, :json, :compact], 
            "Output format (text, json, compact)") do |f|
      options[:format] = f
    end
    
    opts.on("-v", "--verbose", "Verbose output") do
      options[:verbose] = true
    end
    
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!
  
  begin
    vcal_content = ARGF.read
    parser = VcalParser.new(vcal_content)
    event = parser.parse
    viewer = CalendarViewer.new(options)
    viewer.display(event)
  rescue => e
    STDERR.puts "Error: #{e.message}"
    exit 1
  end
end