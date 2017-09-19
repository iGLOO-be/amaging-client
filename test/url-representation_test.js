/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */

const path = require('path')
const fs = require('fs')

const UrlRepresentation = require('../lib/url-representation')

const chai = require('chai')
const { expect } = chai
chai.should()
chai.use(require('chai-fs'))

describe('UrlRepresentation', function () {
  describe('#parse()', function () {
    it('can parse a simple valid amaging string', function () {
      const str = 'http://localhost:1234/test/some/key.jpg'
      const parsed = UrlRepresentation.parse(str)

      expect(parsed).to.be.an('object').instanceof(UrlRepresentation)
      expect(parsed.toString()).to.equal(str)
      expect(parsed._host).to.equal('http://localhost:1234')
      expect(parsed._cid).to.equal('test')
      expect(parsed._key).to.equal('some/key.jpg')

      return expect(parsed.options('100x100').toString())
        .to.equal('http://localhost:1234/test/100x100&/some/key.jpg')
    })

    it('can parse a complex valid amaging string', function () {
      const str = 'https://some.domain.super.real-ly.long:1234/te-s_t/some/path/super-key.jpg'
      const parsed = UrlRepresentation.parse(str + '?test=1')

      expect(parsed).to.be.an('object').instanceof(UrlRepresentation)
      expect(parsed.toString()).to.equal(str)
      expect(parsed._host).to.equal('https://some.domain.super.real-ly.long:1234')
      expect(parsed._cid).to.equal('te-s_t')
      return expect(parsed._key).to.equal('some/path/super-key.jpg')
    })

    it('can not parse a non valid amaging string', function () {
      const str = 'https://localhost:1234/'
      const parsed = UrlRepresentation.parse(str + '?test=1')

      return expect(parsed).to.be.a('null')
    })
  })

  describe('::toString()', function () {
    it('Should return the media path', function () {
      const str = new UrlRepresentation(
        'http://localhost:8888',
        'test',
        'get/file.json'
      )
      return expect(str.toString()).to.be.equals('http://localhost:8888/test/get/file.json')
    })

    it('Should return the media path', function () {
      const str = new UrlRepresentation(
        'http://localhost:8888/',
        '/test',
        'get/file.json'
      )
      return expect(str.toString()).to.be.equals('http://localhost:8888/test/get/file.json')
    })
  })

  describe('::options()', () =>
    it('Should return the media path with options', function () {
      const str = new UrlRepresentation(
        'http://localhost:8888',
        'test',
        'get/file.json'
      )
        .options('100x100')
        .options('negative')
        .options('implode(1)')
      return expect(str.toString()).to.be.equals('http://localhost:8888/test/100x100&negative&implode(1)&/get/file.json')
    })
  )

  return describe('::clearOptions()', () =>
    it('Should clear all options', function () {
      const str = new UrlRepresentation(
        'http://localhost:8888',
        'test',
        'get/file.json'
      )
        .options('100x100')
        .options('negative')
        .options('implode(1)')

      expect(str.toString()).to.be.equals('http://localhost:8888/test/100x100&negative&implode(1)&/get/file.json')

      expect(str
        .clearOptions()
        .toString()
      ).to.be.equals('http://localhost:8888/test/get/file.json')

      return expect(str
        .clearOptions()
        .options('100x100')
        .options('negative')
        .options('implode(1)')
        .toString()
      ).to.be.equals('http://localhost:8888/test/100x100&negative&implode(1)&/get/file.json')
    })
  )
})
