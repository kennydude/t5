'''
T5 is a template engine for NodeJS
'''
parse5 = require("parse5")
#include("./LogicalStatement.coffee")
#include("./ConcatStatement.coffee")
#include("./T5Precompiler.coffee")
#include("./TemplateLoader.coffee")

# @exclude
LogicalStatement = require("./LogicalStatement")
ConcatStatement = require("./ConcatStatement")
T5Precompiler = require("./T5Precompiler")
tl = require("./TemplateLoader")
for k, item of tl
	@[k] = item
# @endexclude
ent = require "ent"

class T5Context
	constructor : () ->
		@element = "this.element"
		@name = "TPL"
		@manageItems = {}
		@buildFunction = ""

class T5
	constructor : (@name) ->
		@name = @name || "TPL"
		@buildFunctionTPL = """
data = data || {};
var context = data;
var stack = [];
var o = "";
var attrs;
var __getvar = function(v){
	v = v.split(".");
	r = context;
	for(var i in v){
		r = r[v[i]];
	}
	return r;
};
if (typeof process !== 'undefined' && process.title == "node") {
	// NodeJS is supported!
	var btoa = function(i){
		return new Buffer(i).toString("base64");
	};
}

"""
		@manageClassTPL = """
this.element = element;
if(!element) throw new Error("An element is required to attach the management class: " + this.constructor.name);
var self = this;

data = data || {};
for(var k in data){ // Copy values into this class
	self["_" + k] = data[k];
}
"""
		@buildFunction = """
// THIS FUNCTION IS AUTOMATICALLY GENERATED
#{@buildFunctionTPL}
"""
		@clsCounter = 0
		@manageClass = """
"""
		@manageClassConstructor = ""
		@cntxt = new T5Context()
		@cntxt.name = @name
		@stack = []

	variableDealer : (varname) ->
		return """
__getvar("#{varname}")
"""
	manageVariableDealer : (varname) ->
		return """
self._#{varname}
"""

	doNodes : (node) ->
		# TODO: Make attrs[] not an array
		bf = """
attrs = {};
attrs["class"] = ["t5-#{@clsCounter}"];\n
"""
		lc = [] # holding place for extra actions
		cEl = false
		doChildren = true

		# Do Attributes
		if node.attrs
			for attr in node.attrs
				#console.log attr
				switch attr.name
					when "class"
						bf += """attrs["class"].push("#{attr.value}");\n"""
					when "data-class", "data-attr"
						l = attr.value.split "\n"
						for line in l
							if line.trim() != ""
								p = line.split(":", 2)
								# TODO: Management functions

								if attr.name == "data-class"
									statement = new LogicalStatement( p[1] )
									statement.variableDealer = @variableDealer
									bf += """if(#{statement.toJS()}){
	attrs["class"].push(#{JSON.stringify(p[0])});
}

"""
								else
									statement = new ConcatStatement( p[1] )
									statement.variableDealer = @variableDealer
									bf += """
attrs[#{JSON.stringify(p[0])}] = #{statement.toJS()};

"""

						cEl = true
					when "data-show"
						statement = new LogicalStatement( attr.value )
						statement.variableDealer = @variableDealer
						bf += """if(!(#{statement.toJS()})){ attrs["style"] = "display: none"; }\n"""
						statement.variableDealer = @manageVariableDealer

						fname = "_inTPL#{@clsCounter}_show"
						for v in statement.vars()
							if !@cntxt.manageItems[v]
								@cntxt.manageItems[v] = []
							@cntxt.manageItems[v].push(fname)

						@manageClass += """
#{@cntxt.name}.prototype.#{fname} = function(){
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
						## advanced stuff
						statement = new LogicalStatement( attr.value )
						statement.variableDealer = @variableDealer
						iv = statement.toJS()
						statement.variableDealer = @manageVariableDealer

						lc.push { "t" : "if", "v" : iv, "mv" : statement.toJS() }

						fname = "_inTPL#{@clsCounter}_if"
						if !@cntxt.manageItems[attr.value]
							@cntxt.manageItems[attr.value] = []
						@cntxt.manageItems[attr.value].push(fname)

						@manageClass += """
#{@cntxt.name}.prototype.#{fname} = function(){
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
					when "data-repeat"
						console.warn("Experimental data-repeat support!!!!")
						statement = new ConcatStatement( attr.value ) # TODO: Single Var Processor
						statement.variableDealer = @variableDealer
						iv = statement.toJS()
						statement.variableDealer = @manageVariableDealer

						@manageClassConstructor += """
this.#{attr.value} = [];
var els = self.element.getElementsByClassName("t5-#{@clsCounter}");
for(var k in #{statement.toJS()}){
	this.#{attr.value}.push( new #{@name}_sub#{@clsCounter}(els[k], #{statement.toJS()}[k]) );
}
this.#{attr.value}.push = function(item){
	// add a new item
	var el = document.createElement("div");
	el.innerHTML = #{@name}_sub#{@clsCounter}.buildFunction(ent, item);
	var elm = el.childNodes[0];
	var els = self.element.getElementsByClassName("t5-#{@clsCounter}");
	el = els[ els.length - 1 ];
	el.parentNode.insertBefore( elm, el.nextSibling );

	var ni = new #{@name}_sub#{@clsCounter}(elm, item);

	return Array.prototype.push.apply(this, [ ni ]);
};\n
"""
						bf = """
// data-repeat
for(var k in #{iv}) {
stack.push(context);
context = #{iv}[k];
// end-data-repeat
#{bf}
"""
						#cEl = true
						lc.push { "t" : "repeat" }

					when "data-html", "data-text"
						statement = new ConcatStatement( attr.value )
						statement.variableDealer = @variableDealer
						iv = statement.toJS()

						fname = "_inTPL#{@clsCounter}_html"

						method = "innerHTML"
						if attr.name == "data-text"
							method = "textContent"
							iv = "ent.encode(#{iv} + \"\");"
							fname = "_inTPL#{@clsCounter}_text"

						for v in statement.vars()
							if !@cntxt.manageItems[v]
								@cntxt.manageItems[v] = []
							@cntxt.manageItems[v].push(fname)

						statement.variableDealer = @manageVariableDealer
						@manageClass += """
#{@cntxt.name}.prototype.#{fname} = function(){
	var self = this;
	var s = #{statement.toJS()};
	this.el#{@clsCounter}.#{method} = s;
};

"""

						lc.push { "t": "html", "v" : """
o += #{iv};
""" }
						cEl = true
						doChildren = false
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
	fa.push( an + '="' + ent.encode(av+"") + '"');
}
o += fa.join(" ") + ">";\n
"""
		else
			#console.log node
			switch node.nodeName
				when "#document-fragment"
					bf = ""
				when "#text"
					bf = """o += #{JSON.stringify(node.value)};\n"""
				when "#comment"
					bf = """o += "<!-- #{node.data} -->";\n"""

		for l in lc
			switch l.t
				when "repeat"
					@stack.push @cntxt
					ele = @cntxt.element
					@cntxt = new T5Context()
					@cntxt.element = ele
					@cntxt.name = "#{@name}_sub#{@clsCounter}"

					@stack.push @manageClassConstructor
					@manageClassConstructor = ""

					@stack.push @manageClass
					@manageClass = ""

				when "html"
					bf += l.v
				when "if"
					@stack.push @cntxt
					@cntxt = new T5Context()
					@cntxt.name = @name
					@cntxt.element = "this.el#{@clsCounter}_pristine"
					@manageClassConstructor += """
if(#{lc.mv}){
	this.el#{@clsCounter}_pristine = this.el#{@clsCounter};
} else{
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
		@cntxt.buildFunction += bf

		for l in lc
			if l.t == "repeat"
				@cntxt.buildFunction = @cntxt.buildFunction.substr( @cntxt.buildFunction.indexOf("// end-data-repeat") )

		@clsCounter += 1
		if node.childNodes && doChildren
			for n in node.childNodes
				if node.childNodes?.length? > 0
					@doNodes(n)

		# End build function
		if node.nodeName.charAt(0) != "#"
			bf = """
o += "</#{node.nodeName}>";\n
"""
			for l in lc
				switch l.t
					when "repeat"
						mcl = @manageClass
						@manageClass = @stack.pop()

						@doManageItems()

						@manageClass += """
// THIS CLASS IS AUTOMATICALLY GENERATED
function #{@cntxt.name} (element, data) {
	#{@manageClassTPL}

	#{@manageClassConstructor}
}
#{@cntxt.name}.buildFunction = function(ent, data){
	#{@buildFunctionTPL}

	#{@cntxt.buildFunction}
	#{bf}

	return o;
}


#{mcl}
"""
						bf += """
context = stack.pop();
}\n
"""
						@manageClassConstructor = @stack.pop()
						@cntxt = @stack.pop()

					when "if"
						@cntxt = @stack.pop()
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
			@cntxt.buildFunction += bf
			@buildFunction += bf

	doManageItems : () ->
		# Setup watcher things
		for k, watching of @cntxt.manageItems
			# TOOD: deal with object.this.that
			#console.log k, watching
			@manageClassConstructor += """
Object.defineProperty(this, "#{k}", {
	get : function(){
		return self._#{k};
	},
	set : function(v){
		self._#{k} = v;
		#{("self.#{v}();\n" for v in watching).join("")}
	}
});

"""

	compile : (str) ->
		parser = new parse5.Parser()
		doc = parser.parseFragment str

		@doNodes(doc)
		@buildFunction += "return o;"

		@doManageItems()

		@manageClass = """
// THIS CLASS IS AUTOMATICALLY GENERATED
function #{@cntxt.name} (element, data) {
	#{@manageClassTPL}

#{@manageClassConstructor}
}
#{@manageClass}
"""

		return new T5Result({
			"buildFunction" : @buildFunction,
			"manageClass" : @manageClass
		})

class T5Result
	constructor : (cns) ->
		for k, value of cns
			@[k] = value
	build : (ent_provided) ->
		if ent_provided
			return new Function( "data", @buildFunction )
		else
			return new Function( "ent", "data", @buildFunction )
	debug : () ->
		console.log "#{k*1+1}: #{line}" for k, line of @buildFunction.toString().split("\n")
		console.log "--------"
		console.log "#{k*1+1}: #{line}" for k, line of @manageClass.split("\n")
		console.log "--------"

@compile = (str, attrs) ->
	attrs = attrs || {};

	p = new T5(attrs.name? || "TPL")

	return p.compile(str)

@compileFile = (str, attrs) ->
	attrs = attrs || {}
	tl = attrs.loader || new T5FileTemplateLoader(".")

	p = new T5(attrs.name? || "TPL")
	preC = new T5Precompiler()
	tpl = preC.precompile(str, tl)

	return p.compile(tpl)
