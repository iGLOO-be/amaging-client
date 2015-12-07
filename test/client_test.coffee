
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

describe 'Client::head', ->
  [client] = []
  before ->
    client = createAmagingClient()
  ###
    HEAD
  ###
  it 'Return file info', (done) ->
    client.head 'get/file.json', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      expect(res.headers['content-type']).to.be.equals('application/json')
      done()

  it 'Return 404 not found', (done) ->
    client.head 'get/not_exists.json', (err, res) ->
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(404)
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
      expect(res.statusCode).to.be.equals(403)
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

  it 'Post an image without content-type', (done) ->
    buffer = fs.readFileSync(path.join(__dirname, '..', '/test/bateau.jpg'))
    client.post 'post/newBoat.jpg', buffer, (err, res) ->
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

  describe 'Remove first / in key', ->
    it 'Classic file post with valid expiration time policy', (done) ->
      policyData = {"expiration": "2017-12-01"}
      client.post '/some/file/with/slash/post/policy.json', 'application/json', '{"post":true}', policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()

    it 'Multipart file post via stream', (done) ->
      stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
      client.post '/some/file/with/slash/post/multipart.json', 'content-type': 'application/json', stream, (err, res) ->
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

describe 'Client::url', ->
  [client] = []
  before ->
    client = createAmagingClient()

  ###
    URL
  ###
  it 'Should return the media path', (done) ->
    str = client.urlStr 'get/file.json'
    expect(str).to.be.equals('http://localhost:8888/test/get/file.json')
    done()

  it 'Should return the media path with options', (done) ->
    str = client
      .url('get/file.json')
      .options('100x100')
      .options('negative')
      .options('implode(1)')
      .toString()
    expect(str).to.be.equals('http://localhost:8888/test/100x100&negative&implode(1)&/get/file.json')
    done()

  it 'Should return the media path with NO options', (done) ->
    str = client
      .url('get/file.json')
      .toString()
    expect(str).to.be.equals('http://localhost:8888/test/get/file.json')
    done()


describe 'Policy', ->

  describe 'Client::post', ->
    [client] = []
    before ->
      client = createAmagingClient()

    ###
      POLICY::POST
    ###
    it 'Classic file post with expired policy', (done) ->
      policyData = {"expiration": "2007-12-01"}
      client.post 'post/policy.json', 'application/json', '{"post":true}', policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(403)
        done()

    it 'Classic file post with valid expiration time policy', (done) ->
      policyData = {"expiration": "2017-12-01"}
      client.post 'post/policy.json', 'application/json', '{"post":true}', policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()

    it 'Multipart file post with expired policy', (done) ->
      policyData = {"expiration": "2008-12-01"}
      stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
      client.post 'post/multipartPolicy.json', 'content-type': 'application/json', stream, policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(403)
        done()

    it 'Multipart file post with valid expiration time policy', (done) ->
      policyData = {"expiration": "2019-12-01"}
      stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
      client.post 'post/multipartPolicy.json', 'content-type': 'application/json', stream, policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()


  describe 'Client::delete', ->
    [client] = []
    before ->
      client = createAmagingClient()

    ###
      POLICY::DEL
    ###
    it 'Delete a file with a expired policy', (done) ->
      policyData = {"expiration": "2007-12-01"}
      client.del 'delete/policy.json', policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(403)
        done()

    it 'Delete a file with a valid policy', (done) ->
      policyData = {"expiration": "2030-12-01"}
      client.del 'delete/policy.json', policyData, (err, res) ->
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()

describe 'Policy Helper', ->

  describe 'Client::policy', ->
    [client] = []
    before ->
      client = createAmagingClient()

    ###
      POLICY::REPRESENTATION
    ###
    it 'Should return an object of the policy expiration in JSON', (done) ->
      str = client
        .policy('+1y')
        .toJSON()
      expect(str).to.be.a('object')
      done()

    it 'Should return the policy expiration in base64', (done) ->
      str = client
        .policy(new Date())
        .toBase64()
      expect(str).to.be.a('string')
      done()

    it 'Should return the complete policy in JSON', (done) ->
      str = client
        .policy(new Date(), '+5y')
        .data('success', 'http://www.igloo.be')
        .cond('start-with', 'test', 'user/eric/')
        .toJSON()
      expect(str).to.be.a('object')
      done()
