'''
Logical Statement Parser

This basically wraps around the PEG.js file

It should be able to deal with

x and y
x != y
d || p

z > r
y < y
o <= y
u >= e
'''
Lparser = require "../peg/LogicalStatement.js"
traverse = require "traverse"

class LogicalStatement
	constructor : (statement) ->
		@variableDealer = (varname) ->
			return varname # Direct but this can be changed!

		@res = @getParser().parse statement

	getParser : () ->
		return Lparser

	javascript : () ->
		return @toJavascript()
	js : () ->
		return @toJavascript()
	toJS : () ->
		return @toJavascript()
	toJavascript : (node) ->
		if(!node)
			node = @res
		o = ''

		for item in node
			if item == null # skip
			else if Array.isArray item
				o += " ( " + @toJavascript(item) + " ) "
			else
				switch item.type
					when "var"
						o += @variableDealer(item.value)
					when "and"
						o += " && "
					when "or"
						o += " || "
					when "equals"
						o += " == "
					when "add"
						o += " + "
					when "literal"
						o += JSON.stringify(item.value)
					when "int"
						o += item.value
					else
						o += item.type

		return o

	vars : () ->
		return @variables()
	'''
	Get all of the variables in this expression
	'''
	variables : () ->
		vars = []
		traverse(@res).map (item) ->
			if item == null #skip
			else if item.type == "var"
				vars.push( item.value )

		return vars

module.exports = LogicalStatement
