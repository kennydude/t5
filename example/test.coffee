# again "Test if it works" thing
t5 = require("../lib/T5")

tpl = t5.compile("""
<div data-show="arguments.length==1" class="egg">
	IK <!-- ok -->
</div>
""")

console.log tpl