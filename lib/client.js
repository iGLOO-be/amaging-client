
const assert = require('assert');
const request = require('request');
const stream = require('stream');
const mime = require('mime');
const debug = require('debug')('amaging-client');

const UrlRepresentation = require('./url-representation');
const { sign } = require('@igloo-be/amaging-policy');

class AmagingClient {
  constructor(options) {
    if (options == null) { options = {}; }
    assert(options.url, 'options.url is mandatory.');
    assert(options.cid, 'options.cid is mandatory.');
    assert(options.key, 'options.key is mandatory.');
    assert(options.secret, 'options.secret is mandatory.');
    this.options = Object.assign({}, options);

    debug('Create client with configuration', this.options);
  }

  async get(key) {
    return request(this.urlStr(key));
  }

  async post(key, headers, body) {
    debug(`Begin POST for key ${key}`);

    if (typeof headers === 'string') {
      const contentType = headers;
      headers = {};
      headers['content-type'] = contentType;
    } else if (headers instanceof stream.Readable || Buffer.isBuffer(headers)) {
      done = body;
      body = headers;

      headers = {};
      headers['content-type'] = mime.lookup(key);
    }

    if (typeof body === 'string' || Buffer.isBuffer(body)) {
      headers['content-length'] = body.length;
    } else {
      return this.postMultipart(key, headers['content-type'], body, done);
    }

    return request.post({
      url: this.urlStr(key),
      body,
      headers: Object.assign({
        'Authorization': 'Bearer ' + await sign(this.options.key, this.options.secret)
          .cond('eq', 'key', key)
          .toJWT()
      }
      , headers)
    }, done);
  }

  // Private method
  async postMultipart(key, contentType, stream) {
    debug(`Begin MULTIPART POST for key ${key}`);
    const req = request.post({
      url: this.urlStr(key),
      headers: {
        'Authorization': 'Bearer ' + await sign(this.options.key, this.options.secret)
          .cond('eq', 'key', key)
          .toJWT()
      }
    });
    form = req.form();
    form.append('file', stream, {
      contentType
    });
    return req;
  }

  async del(key) {
    debug(`Begin DELETE for key ${key}`);
    return request.del({
      url: this.urlStr(key),
      headers: {
        'Authorization': 'Bearer ' + await sign(this.options.key, this.options.secret)
          .cond('eq', 'key', key)
          .toJWT()
      }
    });
  }

  async head(key) {
    debug(`Begin HEAD for key ${key}`);

    const opt =
      {url: this.urlStr(key)};
    return request.head(opt);
  }

  // URL Hepler

  url(key) {
    return new UrlRepresentation(this.options.url, this.options.cid, key);
  }

  urlStr(key) {
    return this.url(key).toString();
  }
}

module.exports = AmagingClient;
