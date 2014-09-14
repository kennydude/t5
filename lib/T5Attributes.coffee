#@exclude
LogicalStatement = require("./LogicalStatement")
ConcatStatement = require("./ConcatStatement")
VariableStatement = require("./VariableStatement")
class T5Context
    constructor : () ->
        @element = "this.element"
        @name = "TPL"
        @manageItems = {}
        @buildFunction = ""
#@endexclude

# T5 Attributes is how we seperate the code for each attribute

@attributes = {}
registerAttribute = (cls, attr) =>
    @attributes[attr] = cls
console.log @attributes

class @T5Attribute
    buildFunction: () ->
        throw new Error("buildFunction() is not implemented")
    managementClass: () ->
        throw new Error("managementClass() is not implemented")
    beforeChildren: () ->
        # Nothing
    afterChildren: () ->
        # Nothing

# More like "legacy" in a way, but I digress
class @SimpleAttribute extends @T5Attribute
    variableDealer : (varname) ->
        # TODO: Make faster!!!!
        return """
__getvar("#{varname}")
"""
    manageVariableDealer : (varname) ->
        return """
self._#{varname}
"""
    buildFunction : () ->
        return {
            body : @bf,
            end : @bf_end
        }
    managementClass : () ->
        events = {}
        if @statement && @fname
            for v in @statement.vars()
                events[v] = @fname

        return {
            body : @manageClass,
            events : events,
            constructor : @manageClassConstructor,
            recordNode : @recordNode
        }

class @ClassAttribute extends @SimpleAttribute
    constructor: (attr, name, cntxt) ->
        @bf = ""
        @manageClass = ""

        l = attr.value.split /[\n\,]/
        for lineNo, line of l
            if line.trim() != ""
                p = line.split(":", 2)

                statement = new LogicalStatement( p[1] )
                statement.variableDealer = @variableDealer
                @bf += """if(#{statement.toJS()}){
attrs["class"].push(#{JSON.stringify(p[0])});
}

"""
                @fname = "_inTPL#{@name}_class#{lineNo}"
                statement.variableDealer = @manageVariableDealer

                cls = p[0].split(" ")
                for k, v of cls
                    if v == ""
                        cls.splice(k, 1)

                flist = ( JSON.stringify(x) for x in cls ).join(",")

                @manageClass += """
#{cntxt.name}.prototype.#{@fname} = function(){
var self = this;
if(#{statement.toJS()}){
this.#{name}.classList.add(#{flist});
} else{
this.#{name}.classList.remove(#{flist});
}
};

"""
registerAttribute(@ClassAttribute, "class")

class @AttributeAttribute extends @SimpleAttribute
    constructor : (attr, name, cntxt) ->
        l = attr.value.split /[\n\,]/
        @bf = ""

        for lineNo, line of l
            if line.trim() != ""
                p = line.split(":", 2)
                statement = new ConcatStatement( p[1] )
                statement.variableDealer = @variableDealer
                @bf += """
attrs[#{JSON.stringify(p[0])}] = #{statement.toJS()};

"""
registerAttribute(@AttributeAttribute, "attr")

class @ShowAttribute extends @SimpleAttribute
    constructor : (attr, name, cntxt) ->
        @statement = new LogicalStatement( attr.value )
        @statement.variableDealer = @variableDealer
        @bf = """if(!(#{@statement.toJS()})){ attrs["style"] = "display: none"; }\n"""
        @statement.variableDealer = @manageVariableDealer

        @fname = "_inTPL#{name}_show"

        @manageClass = """
#{cntxt.name}.prototype.#{@fname} = function(){
var self = this;
var s = '';
if(!(#{@statement.toJS()})){
s = 'display: none';
}
this.#{name}.style.display = s;
};

"""
registerAttribute(@ShowAttribute, "show")

class @ModelAttribute extends @SimpleAttribute
    constructor : (attr, name, cntxt, node) ->
        @statement = new VariableStatement( attr.value )
        @statement.variableDealer = @variableDealer

        accepted = ["input", "textarea", "select"]
        if accepted.indexOf(node.nodeName) == -1
            throw new Error("data-model is only allowed on " + accepted + " elements")

        bf += """
var v = #{statement.toJS()};
if(v){
attrs["value"] = v;
}

"""
        @fname = "_inTPL#{name}_model"

        @statement.variableDealer = @manageVariableDealer
        @manageClass += """
#{cntxt.name}.prototype.#{@fname} = function(){
    var self = this;
    if(this._modelChanged_IP#{name}) return;
    this.#{name}.value = #{statement.toJS()};
};
#{cntxt.name}.prototype._modelChanged_#{name} = function(){
    var self = this;
    this._modelChanged_IP#{name} = true;
    #{statement.toJS()} = this.#{name}.value;
    this.trigger("#{name}-changed");
    this._modelChanged_IP#{name} = false;
}

"""
        f = "function(){ self._modelChanged_#{name}.call(self); }"

        @mangeClassConstructor = """
this._modelChanged_IP#{name} = false;
this.#{name}.addEventListener("change", #{f});
this.#{name}.addEventListener("input", #{f});\n
"""

registerAttribute(@ModelAttribute, "model")

class @IfAttribute extends @SimpleAttribute
    constructor : (attr, name, cntxt, node) ->
        @statement = new LogicalStatement( attr.value )
        @statement.variableDealer = @variableDealer
        @iv = @statement.toJS()
        @statement.variableDealer = @manageVariableDealer
        @readOnly = attr.readOnly

        @fname = "_inTPL#{name}_if"
        @name = name

        @manageClass = """
#{cntxt.name}.prototype.#{@fname} = function(){
var self = this;
var element;

if(#{@statement.toJS()}){
    element = this.#{name}_pristine;
} else{
    element = document.createComment("[t5-hidden]");
}

this.#{name}.parentNode.replaceChild( element, this.#{name} );
this.#{name} = element;
};\n
"""
        @manageClassConstructor = """
if(this.#{name}.getAttribute("data-if") != "1"){
    this.#{name}_pristine = this.#{name};
} else{
    var elx = this.#{name}.firstChild.nodeValue.trim();
    if(elx.substr(0,4) != "[t5]"){
        console.warn("T5W: Comment is not valid!");
    }
    elx = atob(elx.substr(5));

    var el = document.createElement("div");
    el.innerHTML = elx;
    this.#{name}_pristine = el.childNodes[0];
}

    """

    beforeChildren : (t5, bf) ->
        t5.stack.push t5.cntxt
        t5.cntxt = new T5Context()
        t5.cntxt.name = t5.name
        t5.cntxt.element = "this.#{@name}_pristine"

        f = """
o += "<span data-if=\\"1\\" class=\\"t5-#{t5.clsCounter}\\"><!-- [t5] ";\n
"""
        if @readOnly
            f = ''

        return {
            replaceBuildFunction : """
if(#{@iv}){
    #{bf}
} else{
    #{f}
    var to#{@fname} = o;
    o = "";
    #{bf}
}\n
"""
        }

    afterChildren : (t5, bf) ->
        x = t5.cntxt.manageItems
        t5.cntxt = t5.stack.pop()
        for k, v of x
            if !t5.cntxt.manageItems[k]
                t5.cntxt.manageItems[k] = []
            for i in v
                t5.cntxt.manageItems[k].push i

        f = 'o += x + " --\></span>";\n'
        if @readOnly
            f = ''

        return {
            replaceBuildFunction : """
if(#{@iv}){
    #{bf}
} else{
    #{bf}
    var x = btoa(o);
    o = to#{@fname};
    #{f}
}\n
"""
        }

registerAttribute(@IfAttribute, "if")

class @ContentsAttribute extends @SimpleAttribute
    constructor: (attr, name, cntxt) ->
        @statement = new ConcatStatement( attr.value )
        @statement.variableDealer = @variableDealer
        @iv = @statement.toJS()

        @fname = "_inTPL#{name}_html"

        method = "innerHTML"
        if attr.name == "data-text"
            method = "textContent"
            @iv = "ent.encode(#{@iv} + \"\");"
            @fname = "_inTPL#{name}_text"

        @statement.variableDealer = @manageVariableDealer
        @manageClass = """
#{cntxt.name}.prototype.#{@fname} = function(){
var self = this;
var s = #{@statement.toJS()};
this.#{name}.#{method} = s;
};

"""
    beforeChildren : (t5) ->
        return {
            buildFunction: """
o += #{@iv};
""",
            skipChildren : true
        }

registerAttribute(@ContentsAttribute, "text")
registerAttribute(@ContentsAttribute, "html")

class @RepeatAttribute extends @SimpleAttribute
    constructor: (@attr, @name, cntxt, node, t5) ->
        @statement = new VariableStatement( attr.value )
        @statement.variableDealer = @variableDealer
        @iv = @statement.toJS()
        @statement.variableDealer = @manageVariableDealer

        @clsCounter = t5.clsCounter
        @recordNode = true
        @manageClassConstructor = """

"""
    beforeChildren: (t5, bf) ->
        t5.stack.push t5.cntxt
        ele = t5.cntxt.element
        t5.cntxt = new T5Context()
        t5.cntxt.element = ele
        t5.cntxt.name = "#{t5.name}_sub#{@name}"

        t5.stack.push t5.manageClassConstructor
        t5.manageClassConstructor = """
    this.#{@name} = this.element;\n

        """

        t5.stack.push t5.manageClass
        t5.manageClass = ""

        return {
            replaceBuildFunction : """
// data-repeat
for(var k in #{@iv}) {
stack.push(context);
context = #{@iv}[k];
var obj = context;
if(typeof context != "object"){
    context = {};
}
context['$key'] = k;
context['$value'] = obj;
// end-data-repeat
#{bf}
\n
"""
        }

    afterChildren : (t5, bf) ->
        mcl = t5.manageClass
        t5.doManageItems()

        t5.manageClass = t5.stack.pop()

        t5.cntxt.buildFunction = t5.cntxt.buildFunction.substr( t5.cntxt.buildFunction.indexOf("// end-data-repeat") )

        t5.manageClass += """
// THIS CLASS IS AUTOMATICALLY GENERATED
function #{t5.cntxt.name} (element, data) {
#{t5.manageClassTPL}

#{t5.manageClassConstructor}
}
#{t5.cntxt.name}.buildFunction = function(ent, data){
#{t5.buildFunctionTPL}

#{t5.cntxt.buildFunction}
#{bf}

return o;
}

#{mcl}
\n
"""

        t5.manageClassConstructor = t5.stack.pop()

        t5.manageClassConstructor += """
        this.#{@attr.value} = [];
        var els = #{t5.cntxt.element}.getElementsByClassName("t5-#{@clsCounter}");
        for(var k in #{@statement.toJS()}){
            var ni = new #{t5.name}_sub#{@name}( els[k], #{@statement.toJS()}[k]);
            ni.parent = self;
            this.#{@attr.value}.push( ni );
        }
        this.#{@attr.value}.push = function(item){
            return (function(){
                // add a new item
                var el = document.createElement("div");
                el.innerHTML = #{t5.name}_sub#{@name}.buildFunction(ent, item);
                var elm = el.childNodes[0];
                var els = #{t5.cntxt.element}.getElementsByClassName("t5-#{@clsCounter}");
                var is = els[ els.length - 1 ];
                is.parentNode.insertBefore( elm, is.nextSibling );
                var ni = new #{t5.name}_sub#{@name}(elm, item);
                ni.parent = self;

                return Array.prototype.push.apply(this, [ ni ]);
            }).call(self, item);
        };\n
        """

        t5.cntxt = t5.stack.pop()

        return {
            buildFunction : """
                context = stack.pop();
            }\n
            """
        }
registerAttribute(@RepeatAttribute, "repeat")

class @OnAttribute extends @SimpleAttribute
    constructor: (attr, name, cntxt) ->
        @recordNode = true
        @manageClassConstructor = ''

        l = attr.value.split /[\n\,]/
        for lineNo, line of l
            if line.trim() != ""
                p = line.split(":", 2)

                if /^[a-zA-Z 0-9]+$/.test( p[1] )
                    t = p[1].split(" ")
                    a = []
                    for v in t
                        if v.trim() != ""
                            a.push v

                    f = "function(e){ (function(){ this.trigger.apply(this, [#{JSON.stringify(a)}, e, this]); }).call(self); }"
                else
                    f = "function(e){ (function(){ #{p[1]} }).call(self); }"

                @manageClassConstructor += """
this.#{name}.addEventListener(#{JSON.stringify(p[0])}, #{f});\n
"""
registerAttribute(@OnAttribute, "on")
