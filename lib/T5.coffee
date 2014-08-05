'''
T5 is a template engine for NodeJS
'''
parse5 = require("parse5")
ls = require("./LogicalStatement")

class T5
	constructor : (@name) ->
		@name = @name || "TPL"
		@buildFunction = """
// THIS FUNCTION IS AUTOMATICALLY GENERATED
var o = "";
var attrs;
var __getvar = function(v){
	v = v.split(".");
	// todo
};

"""
		@clsCounter = 0
		@manageClass = """
"""
		@manageItems = {}
		@manageClassConstructor = ""

	build : ->
		return new Function( @buildFunction )

	variableDealer : (varname) ->
		return """
__getvar("#{varname}")
"""
	manageVariableDealer : (varname) ->
		return """
self.#{varname}
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
				#console.log attr
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
						statement = new ls( attr.value )
						statement.variableDealer = @variableDealer
						bf += """if(!(#{statement.toJS()})){ attrs["style"] = "display: none"; }\n"""
						statement.variableDealer = @manageVariableDealer

						for v in statement.vars()
							if !@manageItems[v]
								@manageItems[v] = []
							fname = "_inTPL#{@clsCounter}_show"
							@manageItems[v].push(fname)
							@manageClass += """
#{@name}.prototype.#{fname} = function(){
	var self = this;
	var s = '';
	if(!(#{statement.toJS()})){
		s = 'display: none';
	}
	this.el#{@clsCounter}.style.display = s;
};

"""
						cEl = true
					when "data-if"
						## TODO: MAKE THIS WORK IT DOES NOT WORK RIGHT NOW
						## I need to figure out a way to dynamically add/remove this stuff
						lc = { "t" : "if", "v" : attr.value }
					else
						bf += """attrs["#{attr.name}"] = "#{attr.value}";""";

		if cEl
			if node.parentNode.nodeName == "#document-fragment" # Top-level element
				@manageClassConstructor += """
this.el#{@clsCounter} = this.element;

"""
			else
				@manageClassConstructor += """
this.el#{@clsCounter} = this.element.getElementsByClassName("t5-#{@clsCounter}");

"""

		if node.nodeName.charAt(0) != "#" ## TODO: MAKE THIS SAFER
			bf += """
o += "<#{node.nodeName} ";
var fa = [];
for(var an in attrs){
	var av = attrs[an];
	if(an == "class"){ av = av.join(" "); }
	fa.push( an + '="' + av + '"');
}
o += fa.join(" ") + ">";
"""
		else
			#console.log node
			switch node.nodeName
				when "#text"
					bf += """o += #{JSON.stringify(node.value)};"""
				when "#comment"
					bf += """o += "<!-- #{node.data} -->";"""

		if lc != null ## TODO
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
			if lc != null ## TODO
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
		@buildFunction += "return o;"

		# Setup watcher things
		for k, watching of @manageItems
			# TOOD: deal with object.this.that
			console.log k, watching
			@manageClassConstructor += """
Object.defineProperty(this, "#{k}", {
	get : function(){
		return self._#{k};
	},
	set : function(v){
		self._#{k} = v;
		#{"self.#{v}();" for v in watching}
	}
});

"""
		@manageClass = """
// THIS CLASS IS AUTOMATICALLY GENERATED
var #{@name} = function(element) {
	this.element = element;
	var self = this;
#{@manageClassConstructor}
}
#{@manageClass}
"""

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
	p.compile(str)
	return p