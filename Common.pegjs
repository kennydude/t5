placement
  = spacing ob spacing exp spacing cb spacing / item

ob // Opening Bracket
  = "(" { return null }

cb // Closing Bracket
  = ")" { return null }

item
  = not thing / thing

not
 = ("!" / "not" spacing) { return {"type" : "not"} }

thing
  = "true" { return {"type":"true"} } /
    "false" { return {"type":"false"} } /
    digits: [0-9] + { return {"type":"int", "value" : parseInt(digits.join(""), 10) } } /
    "\"" literal:anything "\"" { return {"type":"literal", "value": literal.join("") } } /
    "\'" literal:anythingS "\'" { return {"type":"literal", "value": literal.join("") } } /
    variable

variable
  = variable: [a-zA-z\.\$] + { return { "type":"var", "value":variable.join("") }; }

anything
  = ("\\\"" / [^\"]) +
anythingS
  = ("\\\'" / [^\']) +

spacing
  = [ \t] * { return null }
