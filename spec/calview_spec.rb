require 'rspec'
require_relative '../bin/calview'

RSpec.describe VcalParser do
  let(:basic_vcal) do
    <<~VCAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      SUMMARY:Test Meeting
      DTSTART:20240115T100000Z
      DTEND:20240115T110000Z
      ORGANIZER:MAILTO:organizer@example.com
      DESCRIPTION:This is a test meeting
      LOCATION:Conference Room A
      UID:123456789@example.com
      END:VEVENT
      END:VCALENDAR
    VCAL
  end

  let(:all_day_vcal) do
    <<~VCAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      SUMMARY:All Day Event
      DTSTART;VALUE=DATE:20240115
      DTEND;VALUE=DATE:20240116
      END:VEVENT
      END:VCALENDAR
    VCAL
  end

  let(:recurring_vcal) do
    <<~VCAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      SUMMARY:Weekly Standup
      DTSTART:20240115T090000Z
      DTEND:20240115T093000Z
      RRULE:FREQ=WEEKLY;INTERVAL=1;COUNT=10
      END:VEVENT
      END:VCALENDAR
    VCAL
  end

  let(:timezone_vcal) do
    <<~VCAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      SUMMARY:Team Meeting
      DTSTART;TZID=Eastern Standard Time:20240115T140000
      DTEND;TZID=Eastern Standard Time:20240115T150000
      END:VEVENT
      END:VCALENDAR
    VCAL
  end

  let(:with_attendees_vcal) do
    <<~VCAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      SUMMARY:Project Review
      DTSTART:20240115T140000Z
      DTEND:20240115T150000Z
      ORGANIZER;CN=John Doe:mailto:john@example.com
      ATTENDEE;CN=Jane Smith:mailto:jane@example.com
      ATTENDEE;CN=Bob Johnson:mailto:bob@example.com
      END:VEVENT
      END:VCALENDAR
    VCAL
  end

  describe '#parse' do
    context 'with a basic VCAL' do
      let(:parser) { VcalParser.new(basic_vcal) }
      let(:event) { parser.parse }

      it 'parses the summary' do
        expect(event[:summary]).to eq('Test Meeting')
      end

      it 'parses the organizer' do
        expect(event[:organizer]).to include('organizer@example.com')
      end

      it 'parses the description' do
        expect(event[:description]).to eq('This is a test meeting')
      end

      it 'parses the location' do
        expect(event[:location]).to eq('Conference Room A')
      end

      it 'parses the UID' do
        expect(event[:uid]).to eq('123456789@example.com')
      end

      it 'parses dates correctly' do
        expect(event[:start_date]).to eq('2024-01-15')
        expect(event[:end_date]).to eq('2024-01-15')
      end
    end

    context 'with an all-day event' do
      let(:parser) { VcalParser.new(all_day_vcal) }
      let(:event) { parser.parse }

      it 'identifies as all-day event' do
        expect(event[:times]).to eq('All day')
      end

      it 'parses the summary' do
        expect(event[:summary]).to eq('All Day Event')
      end
    end

    context 'with a recurring event' do
      let(:parser) { VcalParser.new(recurring_vcal) }
      let(:event) { parser.parse }

      it 'parses the recurrence rule' do
        expect(event[:recurrence]).to include('Weekly')
        expect(event[:recurrence]).to include('10 times')
      end
    end

    context 'with timezone information' do
      let(:parser) { VcalParser.new(timezone_vcal) }
      let(:event) { parser.parse }

      it 'parses the summary' do
        expect(event[:summary]).to eq('Team Meeting')
      end

      it 'handles Windows timezone names' do
        expect(event).not_to be_nil
      end
    end

    context 'with attendees' do
      let(:parser) { VcalParser.new(with_attendees_vcal) }
      let(:event) { parser.parse }

      it 'parses the organizer with name' do
        expect(event[:organizer]).to include('John Doe')
        expect(event[:organizer]).to include('john@example.com')
      end

      it 'parses all participants' do
        expect(event[:participants]).to include('Jane Smith')
        expect(event[:participants]).to include('jane@example.com')
        expect(event[:participants]).to include('Bob Johnson')
        expect(event[:participants]).to include('bob@example.com')
      end
    end

    context 'with invalid input' do
      it 'returns nil for empty input' do
        parser = VcalParser.new('')
        expect(parser.parse).to be_nil
      end

      it 'returns nil for non-VCAL input' do
        parser = VcalParser.new('This is not a VCAL file')
        expect(parser.parse).to be_nil
      end
    end
  end

  describe 'private methods' do
    let(:parser) { VcalParser.new('') }

    describe '#extract_date' do
      it 'formats date correctly' do
        result = parser.send(:extract_date, '20240115')
        expect(result).to eq('2024-01-15')
      end

      it 'returns nil for nil input' do
        result = parser.send(:extract_date, nil)
        expect(result).to be_nil
      end
    end

    describe '#extract_time' do
      it 'formats time correctly' do
        result = parser.send(:extract_time, '1430')
        expect(result).to eq('14:30')
      end

      it 'returns nil for nil input' do
        result = parser.send(:extract_time, nil)
        expect(result).to be_nil
      end
    end

    describe '#clean_text' do
      it 'removes newline continuations' do
        result = parser.send(:clean_text, "Line one\n Line two")
        expect(result).to eq('Line one Line two')
      end

      it 'converts escaped newlines' do
        result = parser.send(:clean_text, 'Line one\\nLine two')
        expect(result).to eq("Line one\nLine two")
      end

      it 'returns nil for nil input' do
        result = parser.send(:clean_text, nil)
        expect(result).to be_nil
      end
    end
  end
end

RSpec.describe CalendarViewer do
  let(:event) do
    {
      summary: 'Test Meeting',
      dates: '2024-01-15',
      times: '10:00 - 11:00',
      weekday: 'Monday',
      week: '3',
      location: 'Conference Room',
      organizer: 'John Doe <john@example.com>',
      participants: '   Jane Smith <jane@example.com>',
      description: 'Test description',
      recurrence: 'Weekly',
      status: 'Confirmed',
      priority: 'High'
    }
  end

  describe '#display' do
    context 'with text format' do
      let(:viewer) { CalendarViewer.new(format: :text) }

      it 'displays event in text format' do
        expect { viewer.display(event) }.to output(/WHAT: Test Meeting/).to_stdout
        expect { viewer.display(event) }.to output(/WHEN: 2024-01-15/).to_stdout
        expect { viewer.display(event) }.to output(/WHERE: Conference Room/).to_stdout
      end
    end

    context 'with compact format' do
      let(:viewer) { CalendarViewer.new(format: :compact) }

      it 'displays event in compact format' do
        expect { viewer.display(event) }.to output(/Test Meeting \| 2024-01-15 10:00 - 11:00/).to_stdout
      end
    end

    context 'with JSON format' do
      let(:viewer) { CalendarViewer.new(format: :json) }

      it 'displays event in JSON format' do
        expect { viewer.display(event) }.to output(/"summary": "Test Meeting"/).to_stdout
      end
    end

    context 'with nil event' do
      let(:viewer) { CalendarViewer.new }

      it 'displays error message' do
        expect { viewer.display(nil) }.to output(/Error: Invalid or empty calendar file/).to_stdout
      end
    end
  end
end