# T5

T5 is a templating engine designed to be very different.

Typically you do this:

	data + template => output

But this only works in one place and it doesn't work well when you want to dynamically
change the template but not rewrite the DOM (spoiling any CSS effects etc)

T5 works by producing two outputs:

* Rendering function to do the traditional data+template=>output
* Management class to alter the result dynamically without causing havoc to the
  DOM

This means that if you do not use XML/HTML or the DOM, this is pretty useless
and you shouldn't use it.

This will be used in [WhatTheForms](http://github.com/kennydude/whattheforms)
when this has reached a point where it is stable enough to do so.

More soon haha, this is currently very WIP

## Building

This requires gulp and running `npm install`, but the default gulp task
builds everything required

## Tests

You should have Mocha installed, but we use CoffeeScript, so run

	./runtest.sh

If you can't use `sh` then use the command inside of it
