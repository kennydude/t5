# @exclude
LogicalStatement = require "./LogicalStatement"
# @endexclude
Vparser = require "../peg/VariableStatement.js"

class VariableStatement extends LogicalStatement
    getParser : () ->
        return Vparser

# @exclude
module.exports = VariableStatement
# @endexclude
