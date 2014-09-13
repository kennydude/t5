'''
T5 is a template engine for NodeJS
'''
parse5 = require("parse5")
#include("./LogicalStatement.coffee")
#include("./ConcatStatement.coffee")
#include("./VariableStatement.coffee")
#include("./T5Precompiler.coffee")
#include("./TemplateLoader.coffee")
#include("./T5Attributes.coffee")

# @exclude
LogicalStatement = require("./LogicalStatement")
ConcatStatement = require("./ConcatStatement")
VariableStatement = require("./VariableStatement")
T5Precompiler = require("./T5Precompiler")

merge = (tl) =>
	for k, item of tl
		@[k] = item

merge(require("./TemplateLoader"))
merge(require("./T5Attributes"))
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
var __getvar = function(raw_v, r, x){
	var v = raw_v.split(".");
	if(!r) r = context;
	for(var i in v){
		r = r[v[i]];
	}
	if(r == null){
		if(stack.length > 0){
			if(!x){ x = stack.length-1; }
			else{ x = x - 1; }
			if(x < 0){ return ""; }
			return __getvar(raw_v, stack[x], x);
		}
		return "";
	}
	return r;
};
var doAttributes = function(attrs){
	var fa = [];
	for(var an in attrs){
		var av = attrs[an];
		if(an == "class"){ av = av.join(" "); }
		fa.push( an + '="' + ent.encode(av+"") + '"');
	}
	return fa.join(" ");
}
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
if(element['classList']){
	if(!element.classList.contains("t5-1")){
		this.element = element.getElementsByClassName("t5-1")[0];
	}
}
var self = this;

data = data || {};
for(var k in data){ // Copy values into this class
	self["_" + k] = data[k];
}

// Event Emitter
// based on https://github.com/jeromeetienne/microevent.js
self.bind = function(event, fct){
	self._events = self._events || {};
	self._events[event] = self._events[event]	|| [];
	self._events[event].push(fct);
};
self.unbind	= function(event, fct){
	self._events = self._events || {};
	if( event in self._events === false  )	return;
	self._events[event].splice(self._events[event].indexOf(fct), 1);
};
self.trigger = function(event /* , args... */){
	self._events = self._events || {};
	if( event in self._events === false  )	return;
	for(var i = 0; i < self._events[event].length; i++){
		self._events[event][i].apply(self, Array.prototype.slice.call(arguments, 1));
	}
};
self.on = self.bind;

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

	addSVars : (statement, fname) ->
		for v in statement.vars()
			if !@cntxt.manageItems[v]
				@cntxt.manageItems[v] = []
			@cntxt.manageItems[v].push fname

	doNodes : (node) ->
		bf = """
attrs = { class : [] };\n
"""
		lc = [] # holding place for extra actions
		cEl = false
		doChildren = true
		name = "el#{@clsCounter}"
		afterB = ""

		# Do Attributes
		if node.attrs
			# Try to find name
			for attr in node.attrs
				if attr.name == "data-name"
					name = attr.value

			for attr in node.attrs
				if attr.name == "class"
					bf += """attrs["class"].push(#{JSON.stringify(attr.value)});\n"""
				else if attr.name.substr(0,5) == "data-" or attr.name.substr(0,2) == "v-"
					atName = attr.name.substr( attr.name.indexOf("-")+1 )
					attr.readOnly = false
					if atName.charAt(0) == "$"
						attr.readOnly = true
						atName = atName.substr(1)

					if module.exports.attributes[atName]
						attribute = new module.exports.attributes[atName]( attr, name, @cntxt, node, @ )
						build = attribute.buildFunction()

						if build.body
							bf += build.body
						if build.end
							afterB += build.end

						mc = attribute.managementClass()

						if mc.body && !attr.readOnly
							@manageClass += mc.body
							# If there's a body, it's likely we'll need this!

						if (mc.body || mc.recordNode) && !attr.readOnly
							cEL = true
							if node.parentNode.nodeName == "#document-fragment" # Top-level element
								@manageClassConstructor += """
				this.#{name} = #{@cntxt.element};

				"""
							else
								@manageClassConstructor += """
				this.#{name} = #{@cntxt.element}.getElementsByClassName("t5-#{@clsCounter}")[0];

				"""
						if mc.constructor
							@manageClassConstructor += mc.constructor

						for v, fname of mc.events
							if !@cntxt.manageItems[v]
								@cntxt.manageItems[v] = []
							@cntxt.manageItems[v].push fname

						lc.push attribute
					else
						console.warn "#{atName} is not a currently supported property"
				else
					bf += """attrs["#{attr.name}"] = #{JSON.stringify(attr.value)};""";
			###
			legacy:

			for attr in node.attrs
				#console.log attr
				# TODO data-$class
				switch attr.name
					when "class"
						bf += """attrs["class"].push("#{attr.value}");\n"""
					when "data-class", "data-attr"
						l = attr.value.split "\n"
						for lineNo, line of l
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
									fname = "_inTPL#{@clsCounter}_class#{lineNo}"
									@addSVars(statement, fname)
									statement.variableDealer = @manageVariableDealer

									cls = p[0].split(" ")
									for k, v of cls
										if v == ""
											cls.splice(k, 1)

									flist = ( JSON.stringify(x) for x in cls ).join(",")

									@manageClass += """
#{@cntxt.name}.prototype.#{fname} = function(){
	var self = this;
	if(#{statement.toJS()}){
		this.el#{@clsCounter}.classList.add(#{flist});
	} else{
		this.el#{@clsCounter}.classList.remove(#{flist});
	}
};

"""
								else
									statement = new ConcatStatement( p[1] )
									statement.variableDealer = @variableDealer
									bf += """
attrs[#{JSON.stringify(p[0])}] = #{statement.toJS()};

"""

						cEl = true
					when "data-model"
						statement = new VariableStatement( attr.value )
						statement.variableDealer = @variableDealer

						accepted = ["input", "textarea", "select"]
						if accepted.indexOf(node.nodeName) == -1
							throw new Error("data-model is only allowed on " + accepted + " elements")

						bf += """
var v = #{statement.toJS()};
if(v){
	attrs["value"] = v;
}

"""
						fname = "_inTPL#{@clsCounter}_model"
						@addSVars(statement, fname)

						statement.variableDealer = @manageVariableDealer
						@manageClass += """
#{@cntxt.name}.prototype.#{fname} = function(){
	var self = this;
	if(this._modelChanged_IP#{@clsCounter}) return;
	this.el#{@clsCounter}.value = #{statement.toJS()};
};
#{@cntxt.name}.prototype._modelChanged_#{@clsCounter} = function(){
	var self = this;
	this._modelChanged_IP#{@clsCounter} = true;
	#{statement.toJS()} = this.el#{@clsCounter}.value;
	this.trigger("#{name}-changed");
	this._modelChanged_IP#{@clsCounter} = false;
}

"""
						f = "function(){ self._modelChanged_#{@clsCounter}.call(self); }"
						lc.push {"t" : "model", "x" : """
this._modelChanged_IP#{@clsCounter} = false;
this.el#{@clsCounter}.addEventListener("change", #{f});
this.el#{@clsCounter}.addEventListener("input", #{f});
"""}

						cEl = true
					when "data-show"
						statement = new LogicalStatement( attr.value )
						statement.variableDealer = @variableDealer
						bf += """if(!(#{statement.toJS()})){ attrs["style"] = "display: none"; }\n"""
						statement.variableDealer = @manageVariableDealer

						fname = "_inTPL#{@clsCounter}_show"
						@addSVars(statement, fname)

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
						@addSVars(statement, fname)

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
						statement = new VariableStatement( attr.value )
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
var obj = context;
if(typeof context != "object"){
	context = {};
}
context['$key'] = k;
context['$value'] = obj;
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

						@addSVars(statement, fname)

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
		###
		if cEL
			bf += """attrs["class"].push("t5-#{@clsCounter}");"""

		if node.nodeName.charAt(0) != "#"
			bf += """
o += "<#{node.nodeName} " + doAttributes(attrs) + ">";\n
"""
		else
			switch node.nodeName
				when "#document-fragment"
					bf = ""
				when "#text"
					bf = """o += #{JSON.stringify(node.value)};\n"""
				when "#comment"
					bf = """o += "<!-- #{node.data} -->";\n"""

		bf += afterB

		for l in lc
			r = l.beforeChildren @, bf
			if r
				if r.buildFunction
					bf += r.buildFunction
				if r.replaceBuildFunction
					bf = r.replaceBuildFunction
				if r.skipChildren
					doChildren = false

		###
		for l in lc
			switch l.t
				when "model"
					@manageClassConstructor += l.x
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
if(this.el#{@clsCounter}.getAttribute("data-if") != "1"){
	this.el#{@clsCounter}_pristine = this.el#{@clsCounter};
} else{
	var elx = this.el#{@clsCounter}.firstChild.nodeValue.trim();
	if(elx.substr(0,4) != "[t5]"){
		console.warn("T5W: Comment is not valid!");
	}
	elx = atob(elx.substr(5));

	var el = document.createElement("div");
	el.innerHTML = elx;
	this.el#{@clsCounter}_pristine = el.childNodes[0];
}\n
"""
					bf = """
if(#{l.v}){
	#{bf}
} else{
	o += "<span data-if=\\"1\\" class=\\"t5-#{@clsCounter}\\"><!-- [t5] ";
	var to = o;
	o = "";
	#{bf}
}\n
"""
		###

		@buildFunction += bf
		@cntxt.buildFunction += bf

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
				r = l.afterChildren @, bf
				if r
					if r.buildFunction
						bf += r.buildFunction
					if r.replaceBuildFunction
						bf = r.replaceBuildFunction

			###
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
						x = @cntxt.manageItems
						@cntxt = @stack.pop()
						for k, v of x
							if !@cntxt.manageItems[k]
								@cntxt.manageItems[k] = []
							for i in v
								@cntxt.manageItems[k].push i

						bf = """
if(#{l.v}){
	#{bf}
} else{
	#{bf}
	var x = btoa(o);
	o = to;
	o += x + " --\></span>";
}\n
"""
			###
			@cntxt.buildFunction += bf
			@buildFunction += bf

	doManageItems : () ->
		# Setup watcher things
		mc = ""
		for k, watching of @cntxt.manageItems
			# TOOD: deal with object.this.that
			#console.log k, watching
			mc += """
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
		@manageClassConstructor = "#{mc}\n\n#{@manageClassConstructor}"

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
	debug : (prefix) ->
		if !prefix
			prefix = 1

		pad = (i) ->
			x = i.toString()
			while (x.length != 3)
				x = ' ' + x
			return x

		console.log "#{pad(k*1+prefix)}: #{line}" for k, line of @buildFunction.toString().split("\n")
		console.log "--------"
		console.log "#{pad(k*1+prefix)}: #{line}" for k, line of @manageClass.split("\n")
		console.log "--------"

@compile = (str, attrs) ->
	attrs = attrs || {};

	p = new T5(attrs.name? || "TPL")

	return p.compile(str)

@compileFile = (str, attrs) ->
	attrs = attrs || {}
	tl = attrs.loader || new T5FileTemplateLoader(".")

	p = new T5(attrs['name'] || "TPL")
	preC = new T5Precompiler()
	tpl = preC.precompile(str, tl)

	return p.compile(tpl)
