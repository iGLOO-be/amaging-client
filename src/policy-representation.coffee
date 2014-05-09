
moment = require 'moment'
crypto = require 'crypto'
assert = require 'assert'
utils = require './utils'

genPolicyObject = (date, cond = [], data = {}) ->
  policy =
    expiration: date
    conditions: cond

  for key, val of data
    policy.conditions.push do ->
      d = {}
      d[key] = val
      return d

  return policy

class PolicyRepresentation
  constructor: (date, diffDate, secret) ->
    assert(date, 'Options `date` is mandatory.')
    assert(date, 'Options `secret` is mandatory.')

    @_expiration = utils.offsetDate(date, diffDate)
    @_conditions = []
    @_data = {}
    @_secret = secret

  cond: (action, key, value) ->
    @_conditions.push [ action, key, value ]
    return @

  data: (key, value) ->
    @_data[key] = value
    return @

  toJSON: ->
    return genPolicyObject(@_expiration, @_conditions, @_data)

  toString: ->
    return JSON.stringify(@toJSON())

  toBase64: ->
    return Buffer(@toString(), "utf-8").toString("base64")

  token: ->
    sign = crypto.createHmac('sha1', @_secret)
    sign.update(@toBase64())
    return sign.digest('hex').toLowerCase()

module.exports = PolicyRepresentation