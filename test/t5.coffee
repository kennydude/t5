assert = require("assert")
t5 = require("../lib/T5.coffee")
jsdom = require("jsdom")

compile = (tpl, cb) ->
	tpl = t5.compile(tpl)
	jsdom.env
		html: tpl.build()(),
		src : ["""
#{tpl.manageClass}

window.template = new TPL(document.getElementsByTagName("div")[0]);
"""]
		done: (errors, window) ->
			if errors
				console.log "Errors while using jsdom: ", errors
				throw new Error("JSDom didn't work")
			el = window.document.getElementsByTagName("div")[0]
			cb window.template, el

describe 'T5', () ->
	it 'simple data-show', () ->
		cb = (manage, el) ->
			assert.equal el.getAttribute("style"), "display: none"
			manage.myitem = true
			assert.equal el.getAttribute("style"), ""

		compile("""
<div data-show="myitem" class="egg">
	IK <!-- ok -->
</div>
""", cb)

	it 'simple data-if', () ->
		cb = (manage, el) ->
			console.log el.outerHTML
			manage.myitem = true
			console.log el.outerHTML
			manage.myitem = false
			console.log el.outerHTML
			manage.myitem = true
			console.log el.outerHTML

		compile("""
<div class="something important lmfao">
	<div data-if="myitem" class="egg">
		IK <!-- ok -->
		<span data-html="myvalue"></span>
	</div>
</div>
""", cb)
