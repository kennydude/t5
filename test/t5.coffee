assert = require("assert")
t5 = require("../lib/T5.coffee")
jsdom = require("jsdom")
ent = require "ent"

compile_file = (tpl, cb, data) ->
	tpl = t5.compileFile(tpl, {
		loader : new t5.T5FileTemplateLoader(__dirname)
	})
	tpl.debug()
	use_tpl(tpl, cb, data)

compile = (tpl, cb, data) ->
	tpl = t5.compile(tpl)
	tpl.debug()
	use_tpl(tpl, cb, data)

use_tpl = (tpl, cb, data) ->
	jsdom.env
		html: tpl.build()(ent, data),
		scripts : [ "../node_modules/js-base64/base64.js", "../gen/ent.js" ]
		src : ["""
// This is because atob and btoa are strangely not available
window.btoa = function(i){
	return Base64.encode(i);
};
window.atob = function(i){
	return Base64.decode(i);
}

#{tpl.manageClass}

window.template = new TPL(document.getElementsByTagName("div")[0], #{JSON.stringify(data)});
"""]
		done: (errors, window) ->
			if errors
				console.log "Errors while using jsdom: ", errors
				throw new Error("JSDom didn't work")
			el = window.document.getElementsByTagName("div")[0]
			cb window.template, el

describe 'T5', () ->
	it 'simple data-show', (done) ->
		cb = (manage, el) ->
			assert.equal el.getAttribute("style"), "display: none"
			manage.myitem = true
			assert.equal el.getAttribute("style"), ""
			done()

		compile("""
<div data-show="myitem" class="egg">
	IK <!-- ok -->
</div>
""", cb)

	it 'simple data-if', (done) ->
		cb = (manage, el) ->
			console.log el.outerHTML
			manage.myitem = true
			manage.myvalue = "THIs is my value"
			console.log el.outerHTML
			manage.myitem = false
			manage.myvalue = "xO<bold>OXO</bold>"
			console.log el.outerHTML
			manage.myitem = true
			console.log el.outerHTML
			done()

		compile("""
<div class="something important lmfao">
	<div data-if="myitem" class="egg">
		IK <!-- ok -->
			<span data-text="myvalue"></span>
		<span data-html="myvalue"></span>
	</div>
</div>
""", cb)

	it 'simple data-repeat', (done) ->
		cb = (manage, el) ->
			console.log el.outerHTML
			x = { myvalue : "Test item 3" }
			manage.myitem.push(x)
			console.log el.outerHTML

			manage.myitem[ 0 ].myvalue = "<bold>hi</bold>"
			manage.myitem[ manage.myitem.length - 1 ].myvalue = "xxx"

			console.log el.outerHTML

			manage.myitem[ 1 ].myvalue = "looooool"

			console.log el.outerHTML
			done()

		d = {
			myitem : [
				{myvalue : "TEST ITEM"},
				{myvalue : "TEST ITEM 2"}
			]
		}

		compile("""
<div class="something important lmfao">
	<div data-repeat="myitem" class="egg">
		IK <!-- ok -->
			<span data-text="myvalue"></span>
		<span data-html="myvalue"></span>
	</div>
	<div id="debug"></div>
</div>
""", cb, d)

	it 'should process a remote file fine', (done) ->
		cb = (manage, el) ->
			done()

		compile_file("testA.html", cb, {})

	it 'should process a remote file with include', (done) ->
		cb = (manage, el) ->
			done()

		compile_file("testB.html", cb, {})

	it 'should process a remote file with extends', (done) ->
		cb = (manage, el) ->
			done()

		compile_file("testC.html", cb, {})
