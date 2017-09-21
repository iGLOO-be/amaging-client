
const path = require('path')
const fs = require('fs')

const requireClient = () => require('../lib/client')
const getClient = opt => new (requireClient())(opt)

const createAmagingServer = function (done) {
  const amaging = require('@igloo-be/amaging')({
    customers: {
      test: {
        access: {
          'apiaccess': 'apisecret'
        },
        storage: {
          type: 'local',
          options: {
            path: path.join(__dirname, '../.tmp/storage')
          }
        },
        cacheStorage: {
          type: 'local',
          options: {
            path: path.join(__dirname, '../.tmp/cache')
          }
        }
      }
    }
  })
  amaging.set('port', 8888)
  return amaging.listen(amaging.get('port'), done)
}
const createAmagingClient = () =>
  getClient({
    url: 'http://localhost:8888',
    cid: 'test',
    key: 'apiaccess',
    secret: 'apisecret'
  })

const chai = require('chai')
const { expect } = chai
chai.should()
chai.use(require('chai-fs'))

let [amaging] = Array.from([])

before(done => amaging = createAmagingServer(done))

after(done => amaging.close(done))

describe('Client', function () {
  let [client] = Array.from([])

  it('is a class', () => expect(requireClient()).to.be.a('function'))

  it('can not be instanciate without url, cid, key or secret', function () {
    expect(() => getClient()).throws('options.url is mandatory.')
    expect(() => getClient({url: 'http://test'})).throws('options.cid is mandatory.')
    expect(() => getClient({url: 'http://test', cid: '123'})).throws('options.key is mandatory.')
    return expect(() => getClient({url: 'http://test', cid: '123', key: '123'})).throws('options.secret is mandatory.')
  })

  it('can be instanciate with environment credentials', () =>
    expect(() => client = getClient({url: 'abc', cid: 'abc', key: 'abc', secret: 'abc'})).not.throws()
  )

  it('has a get method', () => expect(client.get).to.be.a('function'))

  it('has a post method', () => expect(client.post).to.be.a('function'))

  it('has a del method', () => expect(client.del).to.be.a('function'))
})

describe('Client::get', function () {
  let [client] = Array.from([])
  before(() => client = createAmagingClient())
  /*
    GET
  */
  it('Client is an object', () => expect(client).to.be.a('object'))

  it('Get a file', done =>
    client.get('get/file.json', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      expect(res.body).to.be.equals('{"json":true}')
      done()
    })
  )
})

describe('Client::head', function () {
  let [client] = Array.from([])
  before(() => client = createAmagingClient())
  /*
    HEAD
  */
  it('Return file info', done =>
    client.head('get/file.json', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      expect(res.headers['content-type']).to.be.equals('application/json')
      done()
    })
  )

  it('Return 404 not found', done =>
    client.head('get/not_exists.json', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(404)
      done()
    })
  )
})

describe('Client::post', function () {
  let [client] = Array.from([])
  before(() => client = createAmagingClient())
  /*
    POST
  */
  // Classic upload
  it('Classic file post with header: content-type: application/json', done =>
    client.post('post/classic.json', {'content-type': 'application/json'}, '{"post":true}', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  )

  it('Classic file post with header: "application/json"', done =>
    client.post('post/classic2.json', 'application/json', '{"post":true}', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  )

  it('Classic file post without content-type: "application/json"', done =>
    client.post('post/classic2.json', '', '{"post":true}', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(403)
      done()
    })
  )

  it('Classic file post with header: contentType: "application/json"', done =>
    client.post('post/classic3.json', {contentType: 'application/json'}, '{"post":true}', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(403)
      done()
    })
  )

  it('Post an existing file via buffer', function (done) {
    const buffer = fs.readFileSync(path.join(__dirname, '..', '/test/expected/get/file.json'))
    return client.post('post/classic4.json', 'application/json', buffer, function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  })

  it('Post an image via stream', function (done) {
    const stream = fs.createReadStream(path.join(__dirname, '..', '/test/bateau.jpg'))
    return client.post('post/bo-bateau.jpg', 'image/jpeg', stream, function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  })

  it('Post an image via buffer', function (done) {
    const buffer = fs.readFileSync(path.join(__dirname, '..', '/test/bateau.jpg'))
    return client.post('post/leBateaudeLoic.jpg', 'image/jpeg', buffer, function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  })

  it('Post an image without content-type', function (done) {
    const buffer = fs.readFileSync(path.join(__dirname, '..', '/test/bateau.jpg'))
    return client.post('post/newBoat.jpg', buffer, function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  })

  // Multipart upload
  it('Multipart file post via stream', function (done) {
    const stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
    return client.post('post/multipart.json', {'content-type': 'application/json'}, stream, function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  })

  return describe('Remove first / in key', function () {
    it('Classic file post with valid expiration time policy', function (done) {
      const policyData = {'expiration': '2017-12-01'}
      return client.post('/some/file/with/slash/post/policy.json', 'application/json', '{"post":true}', policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()
      })
    })

    it('Multipart file post via stream', function (done) {
      const stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
      return client.post('/some/file/with/slash/post/multipart.json', {'content-type': 'application/json'}, stream, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()
      })
    })
  })
})

describe('Client::delete', function () {
  let [client] = Array.from([])
  before(() => client = createAmagingClient())

  /*
    DELETE
  */
  it('Delete a file', done =>
    client.del('delete/rm.json', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(200)
      done()
    })
  )

  it('Delete a file that not exits', done =>
    client.del('delete/not_exists.json', function (err, res) {
      expect(err).to.be.null
      expect(res.statusCode).to.be.equals(404)
      done()
    })
  )
})

describe('Client::url', function () {
  let [client] = Array.from([])
  before(() => client = createAmagingClient())

  /*
    URL
  */
  it('Should return the media path', function (done) {
    const str = client.urlStr('get/file.json')
    expect(str).to.be.equals('http://localhost:8888/test/get/file.json')
    done()
  })

  it('Should return the media path with options', function (done) {
    const str = client
      .url('get/file.json')
      .options('100x100')
      .options('negative')
      .options('implode(1)')
      .toString()
    expect(str).to.be.equals('http://localhost:8888/test/100x100&negative&implode(1)&/get/file.json')
    done()
  })

  it('Should return the media path with NO options', function (done) {
    const str = client
      .url('get/file.json')
      .toString()
    expect(str).to.be.equals('http://localhost:8888/test/get/file.json')
    done()
  })
})

describe('Policy', function () {
  describe('Client::post', function () {
    let [client] = Array.from([])
    before(() => client = createAmagingClient())

    /*
      POLICY::POST
    */
    it('Classic file post with expired policy', function (done) {
      const policyData = {'expiration': '2007-12-01'}
      return client.post('post/policy.json', 'application/json', '{"post":true}', policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(403)
        done()
      })
    })

    it('Classic file post with valid expiration time policy', function (done) {
      const policyData = {'expiration': '2017-12-01'}
      return client.post('post/policy.json', 'application/json', '{"post":true}', policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()
      })
    })

    it('Multipart file post with expired policy', function (done) {
      const policyData = {'expiration': '2008-12-01'}
      const stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
      return client.post('post/multipartPolicy.json', {'content-type': 'application/json'}, stream, policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(403)
        done()
      })
    })

    it('Multipart file post with valid expiration time policy', function (done) {
      const policyData = {'expiration': '2019-12-01'}
      const stream = fs.createReadStream(path.join(__dirname, '..', '/test/expected/get/file.json'))
      return client.post('post/multipartPolicy.json', {'content-type': 'application/json'}, stream, policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()
      })
    })
  })

  return describe('Client::delete', function () {
    let [client] = Array.from([])
    before(() => client = createAmagingClient())

    /*
      POLICY::DEL
    */
    it('Delete a file with a expired policy', function (done) {
      const policyData = {'expiration': '2007-12-01'}
      return client.del('delete/policy.json', policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(403)
        done()
      })
    })

    it('Delete a file with a valid policy', function (done) {
      const policyData = {'expiration': '2030-12-01'}
      return client.del('delete/policy.json', policyData, function (err, res) {
        expect(err).to.be.null
        expect(res.statusCode).to.be.equals(200)
        done()
      })
    })
  })
})

describe('Policy Helper', () =>

  describe('Client::policy', function () {
    let [client] = Array.from([])
    before(() => client = createAmagingClient())

    /*
      POLICY::REPRESENTATION
    */
    it('Should return an object of the policy expiration in JSON', function (done) {
      const str = client
        .policy('+1y')
        .toJSON()
      expect(str).to.be.a('object')
      done()
    })

    it('Should return the policy expiration in base64', function (done) {
      const str = client
        .policy(new Date())
        .toBase64()
      expect(str).to.be.a('string')
      done()
    })

    it('Should return the complete policy in JSON', function (done) {
      const str = client
        .policy(new Date(), '+5y')
        .data('success', 'http://www.igloo.be')
        .cond('start-with', 'test', 'user/eric/')
        .toJSON()
      expect(str).to.be.a('object')
      done()
    })
  })
)
