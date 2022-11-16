# VcalView

VCAL viewer for MUTT (can also be used to view a vcal file in a terminal)

Having used the [vcal2text](https://github.com/davebiffuk/vcal2text) for many
years to view calendar invites in my mutt e-mail client, it started to fail on
newer vcal attachments. It showed only parts of a calendar invite and spit out
lots of errors beyond that. As it is written in perl and carries a bundle of
dependencies, I decided to create my own in Ruby without dependencies. This
solution is leaner (and meaner), and it works.

To use this solution, run `gem install tzinfo` first.

Simply copy `calview.rb` to a suitable place for execution (like your ~/bin
directory) and ensure it is executable (as with `chown 755`).

Then add this to your `.mailcap`:

```
text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
```

...and mutt will neatly display your calendar invites.

This script can also be used to view a vcal file in a terminal simlpy by
issuing the command `calview.rb vcalfile`.


PS: If you encounter any issies or errors, I will gladly fix them Just open an
issue in this repo and I will get to work.
