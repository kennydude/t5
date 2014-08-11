# @exclude
parse5 = require("parse5")
# @endexclude

class T5Precompiler
    constructor : () ->
        @_TargetBlocks = {}
        @_MasterBlocks = {}

    precompileInclude : (node, template_loader) ->
        if node.nodeName == "include"
            # Find the template name
            template_name = ""

            for attr in node.attrs
                if attr.name == "file"
                    template_name = attr.value

            # Load it
            parser = new parse5.Parser()
            doc = parser.parseFragment(template_loader.getTemplate(template_name))

            @replaceNode(node, doc.childNodes)
        else
            if node.childNodes
                for n in node.childNodes
                    @precompileInclude(n, template_loader)

    precompileFindBlocks : (vname, node) ->
        if node.nodeName == "block"
            # Find the block name
            block_name = ""

            for attr in node.attrs
                if attr.name == "id"
                    block_name = attr.value

            @[vname][block_name.toLowerCase()] = node
        else
            if node.childNodes
                for n in node.childNodes
                    @precompileFindBlocks(vname, n)

    replaceNode : (what, withNode) ->
        if !Array.isArray(withNode)
            withNode = [withNode]

        # Prepare switching
        args = [
            what.parentNode.childNodes.indexOf(what),
            1
        ]
        for n in withNode
            args.push n

        # Switch
        what.parentNode.childNodes.splice.apply(
            what.parentNode.childNodes,
            args
        )

    precompileExtends : (node, doc, template_loader) ->
        if node.nodeName == "extends"
            # Find the template name
            template_name = ""

            for attr in node.attrs
                if attr.name == "file"
                    template_name = attr.value

            parser = new parse5.Parser()
            # Precompile anything in here
            preC = new T5Precompiler()
            master_doc = parser.parseFragment(preC.precompile(template_name, template_loader))

            # Target is the template we started with
            # Master is the template we are extending with

            # Find blocks in target
            @precompileFindBlocks("_TargetBlocks", doc)
            # Find blocks in master
            @precompileFindBlocks("_MasterBlocks", master_doc)

            # Replacements
            for name, block of @_TargetBlocks
                if @_MasterBlocks[name]
                    @replaceNode( @_MasterBlocks[name], block.childNodes )

            doc.childNodes = master_doc.childNodes
        else
            if node.childNodes
                for n in node.childNodes
                    @precompileExtends(n, doc, template_loader)

    precompile : (template_name, template_loader) ->
        # This does stuff like <include /> and <extends />
        parser = new parse5.Parser()
        doc = parser.parseFragment(template_loader.getTemplate(template_name))

        # Stage 1: <include />
        @precompileInclude(doc, template_loader)

        # Stage 2: <extends />
        @precompileExtends(doc, doc, template_loader)

        # Stage 3: return
        s = new parse5.TreeSerializer();
        return s.serialize doc

# @exclude
module.exports = T5Precompiler
# @endexclude
