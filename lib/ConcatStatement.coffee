LogicalStatement = require "./LogicalStatement"
Cparser = require "../peg/ConcatSatement.js"

class ConcatStatement extends LogicalStatement
    getParser : () ->
        console.log "getParser()"
        return Cparser

module.exports = ConcatStatement
