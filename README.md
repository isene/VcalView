# VcalView

VCAL viewer for MUTT

Having used the [vcal2text](https://github.com/davebiffuk/vcal2text) for many
years to view calendar invites in my mutt e-mail client, it started to fail on
newer vcal attachments. It showed only parts of a calendar invite and spit out
lots of errors beyond that. As it is written in perl and carries a bundle of
dependencies, I decided to create my own in Ruby without dependencies. This
solution is leaner (and meaner), and it works.

Simply copy `calview.rb` to a suitable place for execution (like your ~/bin
directory) and ensure it is executable (as with `chown 755`).

Then add this to your `.mailcap`:

```
text/calendar; /<pathto>/calview.rb '%s'; copiousoutput
```

...and mutt will neatly display your calendar invites.

PS: If you encounter any issies or errors, I will gladly fix them Just open an
issue in this repo and I will get to work.
