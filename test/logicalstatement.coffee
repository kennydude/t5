assert = require("assert")
ls = require("../lib/LogicalStatement.coffee")

describe 'LogicalStatement', () ->
	it 'should parse bob == john correctly', () ->
		statement = new ls("bob == john")
		assert.deepEqual statement.variables(), ["bob", "john"]
		assert.equal statement.toJS(), "bob == john"

	it 'should parse bob correctly', () ->
		statement = new ls("bob")
		assert.deepEqual statement.variables(), ["bob"]
		assert.equal statement.toJS(), "bob == true"

	it 'should parse bob > john correctly', () ->
		statement = new ls("bob > john")
		assert.deepEqual statement.variables(), ["bob", "john"]
		assert.equal statement.toJS(), "bob>john"

	it 'should parse bob and (john and joe) correctly', () ->
		statement = new ls("bob and (john and joe)")
		assert.deepEqual statement.variables(), ["bob", "john", "joe"]
		assert.equal statement.toJS(), "bob &&  (  ( john && joe )  ) "

	it 'should parse bob == 123 correctly', () ->
		statement = new ls(""" bob = 123  """)
		assert.deepEqual statement.variables(), ["bob"]
		assert.equal statement.toJS(), "bob == 123"

	it 'should parse bob == "JOHN SMITH" correctly', () ->
		statement = new ls("""bob == "JOHN SMITH" """)
		assert.deepEqual statement.variables(), ["bob"]
		assert.equal statement.toJS(), 'bob == "JOHN SMITH"'