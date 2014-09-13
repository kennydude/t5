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
		if(r == null){ break; }
	}
	if(r == null){
		if(stack.length > 0){
			if(!x){ x = stack.length-1; }
			else{ x = x - 1; }
			if(x <= 0){ return ""; }
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
	if(Array.isArray(event)){
		for(var i = 0; i < event.length; i++){
			self.trigger.apply(self, [event[i]].concat( Array.prototype.slice.call(arguments, 1) ));
		}
		return;
	}

	self._events = self._events || {};
	if( !( event in self._events === false  ) ){
		for(var i = 0; i < self._events[event].length; i++){
			self._events[event][i].apply(self, Array.prototype.slice.call(arguments, 1));
		}
	}
	if(self.parent){
		var args = Array.prototype.slice.call(arguments, 1);
		args.unshift(event);
		self.parent.trigger.apply(self.parent, args);
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
		cEL = false
		doChildren = true
		name = "el#{@clsCounter}"
		afterB = ""

		if @clsCounter == 1
			cEL = true

		mcls = ""
		mclsc = ""

		# Do Attributes
		if node.attrs
			# Try to find name
			for attr in node.attrs
				if attr.name == "data-name" || attr.name == "data-id"
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

					if atName == "name" || atName == "id"
						continue # Ignore!

					if module.exports.attributes[atName]
						attribute = new module.exports.attributes[atName]( attr, name, @cntxt, node, @ )
						build = attribute.buildFunction()

						if build.body
							bf += build.body
						if build.end
							afterB += build.end

						mc = attribute.managementClass()

						if mc.body && !attr.readOnly
							mcls += mc.body
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
							mclsc += mc.constructor

						for v, fname of mc.events
							if !@cntxt.manageItems[v]
								@cntxt.manageItems[v] = []
							@cntxt.manageItems[v].push fname

						lc.push attribute
					else
						console.warn "#{atName} is not a currently supported property"
				else
					bf += """attrs["#{attr.name}"] = #{JSON.stringify(attr.value)};""";

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

		@manageClass += mcls
		@manageClassConstructor += mclsc

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
