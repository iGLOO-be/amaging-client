
path = require 'path'
fs = require 'fs'

requireTest = (path) ->
  require((process.env.APP_SRV_COVERAGE || '../') + path)

UrlRepresentation = requireTest('lib/url-representation')

chai = require 'chai'
assert = chai.assert
expect = chai.expect
chai.should()
chai.use(require('chai-fs'))

describe 'UrlRepresentation', ->
  describe '#parse()', ->
    it 'can parse a simple valid amaging string', ->
      str = 'http://localhost:1234/test/some/key.jpg'
      parsed = UrlRepresentation.parse(str)

      expect(parsed).to.be.an('object').instanceof(UrlRepresentation)
      expect(parsed.toString()).to.equal(str)
      expect(parsed._host).to.equal('http://localhost:1234')
      expect(parsed._cid).to.equal('test')
      expect(parsed._key).to.equal('some/key.jpg')

      expect(parsed.options('100x100').toString())
        .to.equal('http://localhost:1234/test/100x100&/some/key.jpg')

    it 'can parse a complex valid amaging string', ->
      str = 'https://some.domain.super.real-ly.long:1234/te-s_t/some/path/super-key.jpg'
      parsed = UrlRepresentation.parse(str + '?test=1')

      expect(parsed).to.be.an('object').instanceof(UrlRepresentation)
      expect(parsed.toString()).to.equal(str)
      expect(parsed._host).to.equal('https://some.domain.super.real-ly.long:1234')
      expect(parsed._cid).to.equal('te-s_t')
      expect(parsed._key).to.equal('some/path/super-key.jpg')

    it 'can not parse a non valid amaging string', ->
      str = 'https://localhost:1234/'
      parsed = UrlRepresentation.parse(str + '?test=1')

      expect(parsed).to.be.a('null')

  describe '::toString()', ->
    it 'Should return the media path', ->
      str = new UrlRepresentation(
        'http://localhost:8888'
        'test'
        'get/file.json'
      )
      expect(str.toString()).to.be.equals('http://localhost:8888/test/get/file.json')

    it 'Should return the media path', ->
      str = new UrlRepresentation(
        'http://localhost:8888/'
        '/test'
        'get/file.json'
      )
      expect(str.toString()).to.be.equals('http://localhost:8888/test/get/file.json')

  describe '::options()', ->
    it 'Should return the media path with options', ->
      str = new UrlRepresentation(
        'http://localhost:8888'
        'test'
        'get/file.json'
      )
        .options('100x100')
        .options('negative')
        .options('implode(1)')
      expect(str.toString()).to.be.equals('http://localhost:8888/test/100x100&negative&implode(1)&/get/file.json')
