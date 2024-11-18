Gem::Specification.new do |s|
  s.name        = 'calview'
  s.version     = '1.1.1'
  s.licenses    = ['Unlicense']
  s.summary     = "VCAL viewer for MUTT (can also be used to view a vcal file in a terminal)"
  s.description = "Having used the [vcal2text](https://github.com/davebiffuk/vcal2text) for many years to view calendar invites in my mutt e-mail client, it started to fail on newer vcal attachments. It showed only parts of a calendar invite and spit out lots of errors beyond that. As it is written in perl and carries a bundle of dependencies, I decided to create my own in Ruby without dependencies. This solution is leaner (and meaner), and it works. Check Github page for more info: https://github.com/isene/calview. New in 1.1.1: Fixed time string for All Day events."
  s.authors     = ["Geir Isene"]
  s.email       = 'g@isene.com'
  s.files       = ["bin/calview.rb"]
  s.executables << 'calview.rb'
  s.homepage    = 'https://isene.com/'
  s.metadata    = { "source_code_uri" => "https://github.com/isene/calview" }
end
