assert = require("assert")
t5 = require("../lib/T5.coffee")
jsdom = require("jsdom")

compile = (tpl, cb) ->
	tpl = t5.compile(tpl)
	jsdom.env(
		tpl.build()(),
	(errors, window) ->
		console.log "done building"
		manage = (new Function """
#{tpl.manageClass}
return TPL;
""")()
		cb new manage( window.document.getElementsByTagName("div")[0] ), window
	)

describe 'T5', () ->
	it 'simple data-show', () ->
		cb = (manage, window) ->
			console.log window.document.outerHTML

			manage.myitem = true

			console.log window.document.outerHTML
		compile("""
<div data-show="myitem" class="egg">
	IK <!-- ok -->
</div>
""", cb)