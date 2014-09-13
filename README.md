# T5

T5 is a templating engine designed to be very different.

Typically you do this:

	data + template => output

But this only works in one place and it doesn't work well when you want to dynamically
change the template but not rewrite the DOM (spoiling any CSS effects etc).

T5 does this:

	template => create-function + management-class

Those two outputs use the same data (if you want to play safe):

* Create Function - This is what you typically use and it'll spit out HTML
  with your data added in.

  **Note:** This output will have t5-x classes and some comments and the odd
  `<span class="t5-x"><!-- [t5] base64 --></span>` and it's perfectly safe
* Management Class - This will take in your DOM once rendered on-screen and
  allow you to dynamically change the data and update affected elements (kind
  of like [VueJS](http://vuejs.org), an inspiration for this project)

This means that if you do not use XML/HTML or the DOM, this is pretty useless
and you shouldn't use it.

This will be used in [WhatTheForms](http://github.com/kennydude/whattheforms)
when this has reached a point where it is stable enough to do so.

More soon haha, this is currently very WIP

## How to use

	var t5 = require("t5");
	tpl = t5.compile( "html string here" );
	var buildFunction = tpl.build();
	var manageClass = tpl.manageClass;

buildFunction is a function which takes two parameters `ent` and `data`. This is
because the nodejs modules don't work too well with dynamically creating
functions :(

manageClass is a string which will generate a class based on the name attribute
(defaults to TPL), which can be initialised on the client like so:

	var ins = new TPL( element, data );

This allows you to dynamically change stuff.

The result is a very limited `T5Result` class to ensure all of the ugly-ness is
hidden away and only useful results are provided for you to use.

## Building

This requires gulp and running `npm install`, but the default gulp task
builds everything required. BUT thanks to browserify, you need to use

	./build.sh

## Tests

You should have Mocha installed, but we use CoffeeScript, so run

	./runtest.sh

If you can't use `sh` then use the command inside of it
