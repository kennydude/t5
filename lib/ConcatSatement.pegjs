// This one concats strings

exp
  = spacing placement spacing operator spacing placement spacing /
    spacing label:item spacing {
      return [ label ]
    }

//include("../Common.pegjs")

operator
  = "+" { return { "type" : "add" } } /
    "&" { return { "type" : "add" } } /
