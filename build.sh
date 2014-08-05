#!/bin/sh
gulp
browserify node_modules/ent/index.js --standalone ent -o gen/ent.js
