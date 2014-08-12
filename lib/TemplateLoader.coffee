class @T5TemplateLoader
    getTemplate: (template_name) ->
        throw new Error("getTemplate() is not defined")

fs = require "fs"
path = require "path"

class @T5FileTemplateLoader
    constructor: (@basedir) ->
    getTemplate: (template_name) ->
        return fs.readFileSync(path.join(@basedir, template_name)).toString()

class @T5FallbackFileTemplateLoader
    constructor: (@basedirs) ->
        if typeof @basedirs == "string"
            @basedirs = [@basedirs]
    getTemplate: (template_name) ->
        for basedir in @basedirs
            filename = path.join basedir, template_name
            if fs.existsSync filename
                return fs.readFileSync(filename).toString()
        throw new Error("File not found")
