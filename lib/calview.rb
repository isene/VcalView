# CalView - VCAL/ICS parser and viewer library
#
# Usage:
#   require 'calview'
#   parser = VcalParser.new(ics_string)
#   event = parser.parse
#   # event is a Hash with :summary, :dates, :times, :organizer, etc.
#
# For formatted output:
#   viewer = CalendarViewer.new(format: :text)
#   viewer.display(event)

require_relative '../bin/calview.rb'
