// I have barely any idea if this is properly done, but it works
// If you do have more of an idea how to do this,
// i would love it if you helped! :D

exp
  = spacing placement spacing operator spacing placement spacing /
    spacing label:item spacing {
      return [ label, { "type" : "equals" }, {"type":"true"} ]
    }

placement
  = spacing ob spacing exp spacing cb spacing / item

ob // Opening Bracket
  = "(" { return null }

cb // Closing Bracket
  = ")" { return null }

item
  = ("!" / "not" spacing) variable / variable

variable
  = "true" { return {"type":"true"} } /
    "false" { return {"type":"false"} } /
    digits: [0-9] + { return {"type":"int", "value" : parseInt(digits.join(""), 10) } } /
    "\"" literal:anything "\"" { return {"type":"literal", "value": literal.join("") } } /
    variable: [a-zA-z\.] + { return { "type":"var", "value":variable.join("") }; }

anything
  = ("\\\"" / [^\"]) +

operator
  = "and" { return {"type":"and"} } /
    "or" { return {"type":"or"} } /
    "&&" { return {"type":"and"} } /
    "||" { return {"type":"or"} } /
    ">" { return {"type":">"} } /
    "<" { return {"type":"<"} } /
    "<=" { return {"type":"<="} } /
    ">=" { return {"type":">="} } /
    "!=" { return {"type":"!="} } /
    ("=="/"=") { return {"type":"equals"} }

spacing
  = [ \t] * { return null }