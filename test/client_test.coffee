
requireTest = (path) ->
  require((process.env.APP_SRV_COVERAGE || '../') + path)

requireClient = -> requireTest('lib/client')
getClient = (opt) -> new (requireClient())(opt)

chai = require 'chai'
assert = chai.assert
expect = chai.expect
chai.should()

describe 'Client', ->
  [client] = []

  it 'is a class', ->
    expect(requireClient()).to.be.a('function')

  it 'can not be instanciate without url, cid, key or secret', ->
    expect(() ->
      getClient()
    ).throws('options.url is mandatory.')
    expect(() ->
      getClient(url: 'http://test')
    ).throws('options.cid is mandatory.')
    expect(() ->
      getClient(url: 'http://test', cid: '123')
    ).throws('options.key is mandatory.')
    expect(() ->
      getClient(url: 'http://test', cid: '123', key: '123')
    ).throws('options.secret is mandatory.')
    expect(() ->
      getClient(url: 'http://test', key: '123')
    ).throws('options.secret is mandatory.')

  it 'can be instanciate with environment credentials', ->
    expect(() ->
      client = getClient(url: process.env.TEST_URL, key: process.env.TEST_KEY, secret: process.env.TEST_SECRET)
    ).not.throws()

  it 'has a get method', ->
    expect(client.get).to.be.a('function')

  it 'has a put method', ->
    expect(client.put).to.be.a('function')
