'''
T5 is a template engine for NodeJS
'''
parse5 = require("parse5")

class T5
	constructor : (@name) ->
		@name = @name || "TPL"
		@buildFunction = """
var o = "";
var attrs;
"""
		@clsCounter = 0
		@manageClass = """
this.element = element;
"""

	doNodes : (node) ->
		bf = """
attrs = {};
attrs["class"] = ["t5-#{@clsCounter}"];
"""
		lc = null
		cEl = false

		# Do Attributes
		if node.attrs
			for attr in node.attrs
				console.log attr
				switch attr.name
					when "class"
						bf += """attrs["class"].push("#{attr.value}");"""
					when "data-class"
						l = attrs.value.split "\n"
						for line in l
							if line.trim() != ""
								p = line.split(":", 2)
								bf += """if(#{p[1]}){ attrs["class"].push("#{p[0]}")  }"""
						cEl = true
					when "data-show"
						bf += """if(#{attr.value}){ attrs["style"] = "display: none"; }\n"""
						@manageItems[ 'do' ] = """this.el#{@clsCounter}.style = value ? '' : 'display: none';"""
						cEl = true
					when "data-if"
						## TODO: MAKE THIS WORK IT DOES NOT WORK RIGHT NOW
						## I need to figure out a way to dynamically add/remove this stuff
						lc = { "t" : "if", "v" : attr.value }
					else
						bf += """attrs["#{attr.name}"] = "#{attr.value}";""";

		if cEl
			@manageClass += """
this.el#{@clsCounter} = this.element.getElementsByClassName("t5-#{@clsCounter}");
"""

		if node.nodeName.charAt(0) != "#" ## TODO: MAKE THIS SAFER
			bf += """
o += "<#{node.nodeName} ";
for(var an in attrs){
	var av = attrs[an];
	if(an == "class"){ av = av.join(" "); }
	o += an + '="' + av + '" ';
}
o += ">";
"""
		else
			console.log node
			switch node.nodeName
				when "#text"
					bf += """o += #{JSON.stringify(node.value)};"""
				when "#comment"
					bf += """o += "<!-- #{node.data} -->";"""

		if lc != null
			bf = """
if(#{lc.v}){
	#{bf}
} else{
	o += "<span class=\\"t5-#{@clsCounter}\\"><!-- [t5]: ";
}
"""

		@buildFunction += bf

		@clsCounter += 1
		if node.childNodes
			for n in node.childNodes
				if node.childNodes?.length? > 0
					@doNodes(n)

		# End build function
		if node.nodeName.charAt(0) != "#"
			bf = """
o += "</#{node.nodeName}>";
"""
			if lc != null
				bf = """
if(#{lc.v}){
	#{bf}
} else{
	o += " [/t5] --></span>";
}
"""
			@buildFunction += bf

	compile : (str) ->
		parser = new parse5.Parser()
		doc = parser.parseFragment str

		@doNodes(doc)
		@buildFunction += "return o;";

		console.log @buildFunction

		bf = new Function(@buildFunction)
		console.log "--------"
		console.log bf()

		console.log "--------"
		console.log @manageClass

		s = new parse5.TreeSerializer()
		console.log s.serialize( doc )

@compile = (str) ->
	p = new T5()
	return p.compile(str)