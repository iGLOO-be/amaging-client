
path = require 'path'
fs = require 'fs'

requireTest = (path) ->
  require((process.env.APP_SRV_COVERAGE || '../') + path)

requireClient = -> requireTest('lib/client')
getClient = (opt) -> new (requireClient())(opt)

createAmagingServer = (done) ->
  amaging = require('igloo-amaging')(
    customers:
      test:
        access:
          'apiaccess': 'apisecret'
        storage:
          type: 'local'
          options:
            path: path.join(__dirname, '../.tmp/storage')
        cacheStorage:
          type: 'local'
          options:
            path: path.join(__dirname, '../.tmp/cache')
  )
  amaging.set('port', 8888)
  amaging.listen amaging.get('port'), done
createAmagingClient = ->
  getClient(
    url: 'http://localhost:8888'
    cid: 'test'
    key: 'apiaccess'
    secret: 'apisecret'
  )

chai = require 'chai'
assert = chai.assert
expect = chai.expect
chai.should()
chai.use(require('chai-fs'))

[amaging] = []

before (done) ->
  amaging = createAmagingServer(done)

after (done) ->
  amaging.close(done)

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

  it 'can be instanciate with environment credentials', ->
    expect(() ->
      client = getClient(url: 'abc', cid: 'abc', key: 'abc', secret: 'abc')
    ).not.throws()

  it 'has a get method', ->
    expect(client.get).to.be.a('function')

  it 'has a post method', ->
    expect(client.post).to.be.a('function')

  it 'has a del method', ->
    expect(client.del).to.be.a('function')

describe 'Client::get', ->
  [client] = []
  before ->
    client = createAmagingClient()
  ###
    GET
  ###
  it 'Client is an object', ->
    expect(client).to.be.a('object')

  it 'Get a file', (done) ->
    client.get 'get/file.json', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      expect(res.body).to.be.equals('{"json":true}')
      done()


describe 'Client::post', ->
  [client] = []
  before ->
    client = createAmagingClient()
  ###
    POST
  ###
  # Classic upload
  it 'Classic file post with header: ' + 'content-type: application/json', (done) ->
    client.post 'post/classic.json', 'content-type': 'application/json', '{"post":true}', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Classic file post with header: ' + '"application/json"', (done) ->
    client.post 'post/classic2.json', 'application/json', '{"post":true}', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Classic file post without content-type: ' + '"application/json"', (done) ->
    client.post 'post/classic2.json', '','{"post":true}', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Classic file post with header: ' + 'contentType: "application/json"', (done) ->
    client.post 'post/classic3.json', contentType: 'application/json', '{"post":true}', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(403)
      done()

  it 'Post an existing file via buffer', (done) ->
    buffer = fs.readFileSync(path.join(__dirname, '..', '/test/expected/get/file.json'))
    client.post 'post/classic4.json', 'application/json', buffer, (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Post an image via stream', (done) ->
    stream = fs.createReadStream(path.join(__dirname, '..', '/test/bateau.jpg'))
    client.post 'post/bo-bateau.jpg', 'image/jpeg', stream, (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Post an image via buffer', (done) ->
    buffer = fs.readFileSync(path.join(__dirname, '..', '/test/bateau.jpg'))
    client.post 'post/leBateaudeLoic.jpg', 'image/jpeg', buffer, (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Post an image with buffer content-type', (done) ->
    buffer = fs.readFileSync(path.join(__dirname, '..', '/test/bateau.jpg'))
    buffContentType = fs.readFileSync(path.join(__dirname, '..', '/test/content-type.txt'))
    client.post 'post/leBateaudeLoic.jpg', buffContentType, buffer, (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  # Multipart upload
  it 'Multipart file post via stream', (done) ->
    stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
    client.post 'post/multipart.json', 'content-type': 'application/json', stream, (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()


describe 'Client::delete', ->
  [client] = []
  before ->
    client = createAmagingClient()

  ###
    DELETE
  ###
  it 'Delete a file', (done) ->
    client.del 'delete/rm.json', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()

  it 'Delete a file that not exits', (done) ->
    client.del 'delete/not_exists.json', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(404)
      done()
