
assert = require 'assert'
_ = require 'lodash'
request = require 'request'
crypto = require 'crypto'
stream = require 'stream'
path = require 'path'
mime = require 'mime'
debug = require('debug')('amaging-client')

UrlRepresentation = require './url-representation'
PolicyFactory = require 'igloo-amaging-policy'

utils =
  sha1: (data) ->
    crypto.createHash('sha1')
      .update(data)
      .digest('hex')

  isStream: (obj) ->
    obj instanceof stream.Readable

  hmacSha1: (data, secret) ->
    sign = crypto.createHmac('sha1', secret)
    sign.update(data)
    return sign.digest('hex').toLowerCase()

  encodeBase64: (str) ->
    return Buffer(str, "utf-8").toString("base64")

  requestPolicyFileToken: (filePath, str) ->
    json = if _.isString(str) then str else JSON.stringify(str)
    policy = utils.encodeBase64(json)
    token = utils.hmacSha1(policy, 'apisecret')
    return {
      access: 'apiaccess'
      file_path: path.join(__dirname, '..', filePath)
      token: token
      policy: policy
    }

genToken = (key, options, contentType, contentLength) ->
  # Remove first '/'. It is always ignored by amaging
  key = key.replace(/^\/+/, '')

  str = _.compact([
    options.cid,
    options.key,
    options.secret,
    key,
    contentType,
    contentLength
  ]).join('')

  debug "Generate SHA token for string: #{str}"
  hash = utils.sha1(str)
  debug "Generated SHA token: #{hash}"

  return hash

class AmagingClient
  constructor: (options = {}) ->
    assert(options.url, 'options.url is mandatory.')
    assert(options.cid, 'options.cid is mandatory.')
    assert(options.key, 'options.key is mandatory.')
    assert(options.secret, 'options.secret is mandatory.')
    @options = _.extend {}, options

    debug 'Create client with configuration', @options

  get: (key, done) ->
    request(@urlStr(key), done)

  post: (key, headers, body, policy, done) ->
    mutlipart = false

    debug "Begin POST for key #{key}"

    if _.isString(headers)
      contentType = headers
      headers = {}
      headers['content-type'] = contentType
    else if utils.isStream(headers) or Buffer.isBuffer(headers)
      done = body
      body = headers

      headers = {}
      headers['content-type'] = mime.lookup(key)

    if _.isFunction(policy)
      done = policy
      policy = null

    if _.isString(body) or Buffer.isBuffer(body)
      headers['content-length'] = body.length
    else
      mutlipart = true

    if mutlipart
      return @postMultipart key, headers['content-type'], body, policy, done

    unless policy
      token = genToken(key, @options, headers['content-type'], headers['content-length'])
      opt =
        url: @urlStr(key)
        body: body
        headers: _.extend
          'x-authentication': @options.key
          'x-authentication-token': token
        , headers
      request.post opt, done

    else
      pol = utils.requestPolicyFileToken(key, policy)
      opt =
        url: @urlStr(key)
        headers:
          'content-type': headers['content-type']
          'content-length': headers['content-length']
          'x-authentication': @options.key
          'x-authentication-token': pol.token
          'x-authentication-policy': pol.policy
      request.post opt, done

  # Private method
  postMultipart: (key, contentType, stream, policy, done) ->
    debug "Begin MULTIPART POST for key #{key}"

    unless policy
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
    else
      pol = utils.requestPolicyFileToken(key, policy)
      opt =
        url: @urlStr(key)
        headers:
          'x-authentication': @options.key
          'x-authentication-token': pol.token
          'x-authentication-policy': pol.policy

      req = request.post opt, done

      form = req.form()
      form.append('file', stream, {
        contentType: contentType
      })

      return req

  del: (key, policy, done) ->
    debug "Begin DELETE for key #{key}"

    if _.isFunction(policy)
      done = policy
      policy = null

    unless policy
      token = genToken(key, @options)
      opt =
        url: @urlStr(key)
        headers:
          'x-authentication': @options.key
          'x-authentication-token': token
      request.del opt, done
    else
      pol = utils.requestPolicyFileToken(key, policy)
      opt =
        url: @urlStr(key)
        headers:
          'x-authentication': @options.key
          'x-authentication-token': pol.token
          'x-authentication-policy': pol.policy
      request.del opt, done

  head: (key, done) ->
    debug "Begin HEAD for key #{key}"

    opt =
      url: @urlStr(key)
    request.head opt, done

  # URL Hepler

  url: (key) ->
    new UrlRepresentation(@options.url, @options.cid, key)

  urlStr: (key) ->
    @url(key).toString()

  # Policy Helper

  policy: (date, diff) ->
    unless @policyFactory
      @policyFactory = new PolicyFactory(@options.secret)
    @policyFactory.represent date, diff

module.exports = AmagingClient
