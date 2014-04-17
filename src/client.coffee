
assert = require 'assert'
_ = require 'lodash'

class AmagingClient
  constructor: (options = {}) ->
    assert(options.url, 'options.url is mandatory.')
    assert(options.cid, 'options.cid is mandatory.')
    assert(options.key, 'options.key is mandatory.')
    assert(options.secret, 'options.secret is mandatory.')
    @options = _.extend {}, options

  get: (key) ->

  put: (key) ->

module.exports = AmagingClient
