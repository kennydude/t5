'''
T5 is a template engine for NodeJS
'''
parse5 = require("parse5")
ls = require("./LogicalStatement")
cs = require("./ConcatStatement")
ent = require "ent"

class T5Context
	constructor : () ->
		@element = "this.element"

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
	return "todo{return value}";
};
if (typeof process !== 'undefined' && process.title == "node") {
	// NodeJS is supported!
	var btoa = function(i){
		return new Buffer(i).toString("base64");
	};
}

"""
		@clsCounter = 0
		@manageClass = """
"""
		@manageItems = {}
		@manageClassConstructor = ""
		@cntxt = new T5Context()

	build : ->
		return new Function( "ent", @buildFunction )

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
attrs["class"] = ["t5-#{@clsCounter}"];\n
"""
		lc = null # holding place for extra actions
		cEl = false
		oldContext = null

		# Do Attributes
		if node.attrs
			for attr in node.attrs
				#console.log attr
				switch attr.name
					when "class"
						bf += """attrs["class"].push("#{attr.value}");\n"""
					when "data-class"
						l = attrs.value.split "\n"
						for line in l
							if line.trim() != ""
								p = line.split(":", 2)
								bf += """if(#{p[1]}){ attrs["class"].push("#{p[0]}")  }\n"""
						cEl = true
					when "data-show"
						statement = new ls( attr.value )
						statement.variableDealer = @variableDealer
						bf += """if(!(#{statement.toJS()})){ attrs["style"] = "display: none"; }\n"""
						statement.variableDealer = @manageVariableDealer

						fname = "_inTPL#{@clsCounter}_show"
						for v in statement.vars()
							if !@manageItems[v]
								@manageItems[v] = []
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

						## Maybe need another expression parser if we want more
						## advanced stuff
						statement = new ls( attr.value )
						statement.variableDealer = @variableDealer
						iv = statement.toJS()
						statement.variableDealer = @manageVariableDealer

						lc = { "t" : "if", "v" : iv, "mv" : statement.toJS() }

						fname = "_inTPL#{@clsCounter}_if"
						if !@manageItems[attr.value]
							@manageItems[attr.value] = []
						@manageItems[attr.value].push(fname)

						@manageClass += """
#{@name}.prototype.#{fname} = function(){
	var self = this;
	var element;
	if(#{statement.toJS()}){
		element = this.el#{@clsCounter}_pristine;
	} else{
		element = document.createComment("[t5-hidden]");
	}

	this.el#{@clsCounter}.parentNode.replaceChild( element, this.el#{@clsCounter} );
	this.el#{@clsCounter} = element;
};

"""

						cEl = true
					when "data-html", "data-text"
						statement = new cs( attr.value )
						statement.variableDealer = @variableDealer
						iv = statement.toJS()

						fname = "_inTPL#{@clsCounter}_html"
						for v in statement.vars()
							if !@manageItems[v]
								@manageItems[v] = []
							@manageItems[v].push(fname)

						method = "innerHTML"
						if attr.name == "data-text"
							method = "textContent"
							iv = "ent.encode(#{iv});"

						statement.variableDealer = @manageVariableDealer
						@manageClass += """
#{@name}.prototype.#{fname} = function(){
	var self = this;
	var s = #{statement.toJS()};
	this.el#{@clsCounter}.#{method} = s;
};

"""

						lc = { "t": "html", "v" : """
o += #{iv};
""" }
						cEl = true
					else
						bf += """attrs["#{attr.name}"] = "#{attr.value}";""";

		if cEl
			if node.parentNode.nodeName == "#document-fragment" # Top-level element
				@manageClassConstructor += """
this.el#{@clsCounter} = #{@cntxt.element};

"""
			else
				@manageClassConstructor += """
this.el#{@clsCounter} = #{@cntxt.element}.getElementsByClassName("t5-#{@clsCounter}")[0];

"""

		if node.nodeName.charAt(0) != "#" ## TODO: MAKE THIS SAFER
			bf += """
o += "<#{node.nodeName} ";
var fa = [];
for(var an in attrs){
	var av = attrs[an];
	if(an == "class"){ av = av.join(" "); }
	fa.push( an + '="' + ent.encode(av) + '"');
}
o += fa.join(" ") + ">";\n
"""
		else
			#console.log node
			switch node.nodeName
				when "#text"
					bf = """o += #{JSON.stringify(node.value)};\n"""
				when "#comment"
					bf = """o += "<!-- #{node.data} -->";\n"""

		if lc != null
			switch lc.t
				when "html"
					bf += lc.v
				when "if"
					oldContext = @cntxt
					@cntxt = new T5Context()
					@cntxt.element = "this.el#{@clsCounter}_pristine"
					@manageClassConstructor += """
if(#{lc.mv}){
	this.el#{@clsCounter}_pristine = this.el#{@clsCounter};
} else{
	//this.el#{@clsCounter}_pristine = document.createElement("#{node.nodeName}");

	var elx = this.el#{@clsCounter}.childNodes[0].nodeValue.trim();
	if(elx.substr(0,3) != "[t5]"){
		console.warn("T5W: Comment is not valid!");
	}
	elx = atob(elx.substr(5));

	var el = document.createElement("div");
	el.innerHTML = elx;
	this.el#{@clsCounter}_pristine = el.childNodes[0];
}\n
"""
					bf = """
if(#{lc.v}){
	#{bf}
} else{
	o += "<span class=\\"t5-#{@clsCounter}\\"><!-- [t5] ";
	var to = o;
	o = "";
	#{bf}
}\n
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
o += "</#{node.nodeName}>";\n
"""
			if lc != null ## TODO
				switch lc.t
					when "if"
						@cntxt = oldContext
						bf = """
if(#{lc.v}){
	#{bf}
} else{
	#{bf}
	var x = btoa(o);
	o = to;
	o += x + " --\></span>";
}\n
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

		bf = new Function(@buildFunction)
		console.log "#{k*1+1}: #{line}" for k, line of bf.toString().split("\n")


		#console.log "--------"
		#console.log bf()
		console.log "--------"
		console.log @manageClass
		console.log "--------"

@compile = (str) ->
	p = new T5()
	p.compile(str)
	return p
