# @exclude
LogicalStatement = require "./LogicalStatement"
# @endexclude
Cparser = require "../peg/ConcatSatement.js"

class ConcatStatement extends LogicalStatement
    getParser : () ->
        return Cparser

# @exclude
module.exports = ConcatStatement
# @endexclude
