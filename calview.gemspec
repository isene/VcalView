Gem::Specification.new do |s|
  s.name        = 'calview'
  s.version     = '2.0.0'
  s.licenses    = ['Unlicense']
  s.summary     = "VCAL/iCalendar viewer for terminal and mutt with multiple output formats"
  s.description = "A robust VCAL/iCalendar viewer that parses calendar invites and displays them in a readable format. Perfect for mutt email client integration and terminal viewing. Features include timezone support, recurrence parsing, multiple output formats (text, JSON, compact), and comprehensive error handling. Originally created to replace vcal2text with a leaner Ruby solution."
  s.authors     = ["Geir Isene"]
  s.email       = 'g@isene.com'
  s.files       = ["bin/calview.rb"]
  s.executables << 'calview.rb'
  s.homepage    = 'https://isene.com/'
  s.metadata    = { 
    "source_code_uri" => "https://github.com/isene/calview",
    "bug_tracker_uri" => "https://github.com/isene/calview/issues",
    "changelog_uri"   => "https://github.com/isene/calview/blob/master/CHANGELOG.md"
  }
  s.required_ruby_version = '>= 2.5.0'
  s.add_development_dependency 'tzinfo', '~> 2.0'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rake', '~> 13.0'
end
