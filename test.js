// THIS CLASS IS AUTOMATICALLY GENERATED
var TPL = function(element, data) {
	this.element = element;
if(!element) throw new Error("An element is required to attach the management class");
var self = this;

data = data || {};
for(var k in data){ // Copy values into this class
	self[k] = data[k];
}


}
// THIS CLASS IS AUTOMATICALLY GENERATED
var TPL_sub3 = function(element, data) {
	this.element = element;
if(!element) throw new Error("An element is required to attach the management class");
var self = this;

data = data || {};
for(var k in data){ // Copy values into this class
	self[k] = data[k];
}

	this.buildFunction = function(data){
		o += "\n\tIK ";
o += "<!--  ok  -->";
o += "\n\t\t";
attrs = {};
attrs["class"] = ["t5-7"];
o += "<span ";
var fa = [];
for(var an in attrs){
	var av = attrs[an];
	if(an == "class"){ av = av.join(" "); }
	fa.push( an + '="' + ent.encode(av+"") + '"');
}
o += fa.join(" ") + ">";
o += ent.encode(__getvar("myvalue") + "");;o += "</span>";
o += "\n\t";
attrs = {};
attrs["class"] = ["t5-9"];
o += "<span ";
var fa = [];
for(var an in attrs){
	var av = attrs[an];
	if(an == "class"){ av = av.join(" "); }
	fa.push( an + '="' + ent.encode(av+"") + '"');
}
o += fa.join(" ") + ">";
o += __getvar("myvalue");o += "</span>";
o += "\n";

		o += "</div>";

	}

	this.el7 = this.element.getElementsByClassName("t5-7")[0];
this.el9 = this.element.getElementsByClassName("t5-9")[0];
Object.defineProperty(this, "myvalue", {
	get : function(){
		return self._myvalue;
	},
	set : function(v){
		self._myvalue = v;
		self._inTPL7_text();
self._inTPL9_html();

	}
});

}

TPL_sub3.prototype._inTPL7_text = function(){
	var self = this;
	var s = self.myvalue;
	this.el7.textContent = s;
};
TPL_sub3.prototype._inTPL9_html = function(){
	var self = this;
	var s = self.myvalue;
	this.el9.innerHTML = s;
};
