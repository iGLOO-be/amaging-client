
assert = require 'assert'
_ = require 'lodash'
request = require 'request'
crypto = require 'crypto'
stream = require 'stream'
path = require 'path'
mime = require 'mime'

UrlRepresentation = require './url-representation'

utils =
  sha1: (data) ->
    crypto.createHash('sha1')
      .update(data)
      .digest('hex')

  isStream: (obj) ->
    obj instanceof stream.Readable

genToken = (key, options, contentType, contentLength) ->
  utils.sha1(_.compact([
    options.cid,
    options.key,
    options.secret,
    key,
    contentType,
    contentLength
  ]).join(''))

class AmagingClient
  constructor: (options = {}) ->
    assert(options.url, 'options.url is mandatory.')
    assert(options.cid, 'options.cid is mandatory.')
    assert(options.key, 'options.key is mandatory.')
    assert(options.secret, 'options.secret is mandatory.')
    @options = _.extend {}, options

  get: (key, done) ->
    request(@urlStr(key), done)

  post: (key, headers, body, done) ->
    mutlipart = false

    if _.isString(headers)
      headers = {}
      headers['content-type'] = headers
    else if utils.isStream(headers) or Buffer.isBuffer(headers)
      done = body
      body = headers
      headers = {}
      headers['content-type'] = mime.lookup(key)

    if _.isString(body) or Buffer.isBuffer(body)
      headers['content-length'] = body.length
    else
      mutlipart = true

    if mutlipart
      return @postMultipart key, headers['content-type'], body, done

    token = genToken(key, @options, headers['content-type'], headers['content-length'])
    opt =
      url: @urlStr(key)
      body: body
      headers: _.extend
        'x-authentication': @options.key
        'x-authentication-token': token
      , headers
    request.post opt, done

  # Private method
  postMultipart: (key, contentType, stream, done) ->
    token = genToken(key, @options)
    opt =
      url: @urlStr(key)
      headers:
        'x-authentication': @options.key
        'x-authentication-token': token

    req = request.post opt, done

    form = req.form()
    form.append('file', stream, {
      contentType: contentType
    })

    return req

  del: (key, done) ->
    token = genToken(key, @options)
    opt =
      url: @urlStr(key)
      headers:
        'x-authentication': @options.key
        'x-authentication-token': token
    request.del opt, done

  head: (key, done) ->
    opt =
      url: @urlStr(key)
    request.head opt, done

  url: (key) ->
    new UrlRepresentation(@options.url, @options.cid, key)

  urlStr: (key) ->
    @url(key).toString()

module.exports = AmagingClient
