
const assert = require('assert');
const request = require('request');
const crypto = require('crypto');
const stream = require('stream');
const path = require('path');
const mime = require('mime');
const debug = require('debug')('amaging-client');

const UrlRepresentation = require('./url-representation');
const PolicyFactory = require('@igloo-be/amaging-policy');

var utils = {
  sha1(data) {
    return crypto.createHash('sha1')
      .update(data)
      .digest('hex');
  },

  isStream(obj) {
    return obj instanceof stream.Readable;
  },

  hmacSha1(data, secret) {
    const sign = crypto.createHmac('sha1', secret);
    sign.update(data);
    return sign.digest('hex').toLowerCase();
  },

  encodeBase64(str) {
    return Buffer(str, "utf-8").toString("base64");
  },

  requestPolicyFileToken(filePath, str) {
    const json = typeof str === 'string' ? str : JSON.stringify(str);
    const policy = utils.encodeBase64(json);
    const token = utils.hmacSha1(policy, 'apisecret');
    return {
      access: 'apiaccess',
      file_path: path.join(__dirname, '..', filePath),
      token,
      policy
    };
  }
};

const genToken = function(key, options, contentType, contentLength) {
  // Remove first '/'. It is always ignored by amaging
  key = key.replace(/^\/+/, '');

  const str = [
    options.cid,
    options.key,
    options.secret,
    key,
    contentType,
    contentLength
  ].filter(Boolean).join('');

  debug(`Generate SHA token for string: ${str}`);
  const hash = utils.sha1(str);
  debug(`Generated SHA token: ${hash}`);

  return hash;
};

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

  get(key, done) {
    return request(this.urlStr(key), done);
  }

  post(key, headers, body, policy, done) {
    let opt, token;
    let mutlipart = false;

    debug(`Begin POST for key ${key}`);

    if (typeof headers === 'string') {
      const contentType = headers;
      headers = {};
      headers['content-type'] = contentType;
    } else if (utils.isStream(headers) || Buffer.isBuffer(headers)) {
      done = body;
      body = headers;

      headers = {};
      headers['content-type'] = mime.lookup(key);
    }

    if (typeof policy === 'function') {
      done = policy;
      policy = null;
    }

    if (typeof body === 'string' || Buffer.isBuffer(body)) {
      headers['content-length'] = body.length;
    } else {
      mutlipart = true;
    }

    if (mutlipart) {
      return this.postMultipart(key, headers['content-type'], body, policy, done);
    }

    if (!policy) {
      token = genToken(key, this.options, headers['content-type'], headers['content-length']);
      opt = {
        url: this.urlStr(key),
        body,
        headers: Object.assign({
          'x-authentication': this.options.key,
          'x-authentication-token': token
        }
        , headers)
      };
      return request.post(opt, done);

    } else {
      const pol = utils.requestPolicyFileToken(key, policy);
      opt = {
        url: this.urlStr(key),
        headers: {
          'content-type': headers['content-type'],
          'content-length': headers['content-length'],
          'x-authentication': this.options.key,
          'x-authentication-token': pol.token,
          'x-authentication-policy': pol.policy
        }
      };
      return request.post(opt, done);
    }
  }

  // Private method
  postMultipart(key, contentType, stream, policy, done) {
    let form, opt, req, token;
    debug(`Begin MULTIPART POST for key ${key}`);

    if (!policy) {
      token = genToken(key, this.options);
      opt = {
        url: this.urlStr(key),
        headers: {
          'x-authentication': this.options.key,
          'x-authentication-token': token
        }
      };

      req = request.post(opt, done);

      form = req.form();
      form.append('file', stream, {
        contentType
      });

      return req;
    } else {
      const pol = utils.requestPolicyFileToken(key, policy);
      opt = {
        url: this.urlStr(key),
        headers: {
          'x-authentication': this.options.key,
          'x-authentication-token': pol.token,
          'x-authentication-policy': pol.policy
        }
      };

      req = request.post(opt, done);

      form = req.form();
      form.append('file', stream, {
        contentType
      });

      return req;
    }
  }

  del(key, policy, done) {
    let opt, token;
    debug(`Begin DELETE for key ${key}`);

    if (typeof policy === 'function') {
      done = policy;
      policy = null;
    }

    if (!policy) {
      token = genToken(key, this.options);
      opt = {
        url: this.urlStr(key),
        headers: {
          'x-authentication': this.options.key,
          'x-authentication-token': token
        }
      };
      return request.del(opt, done);
    } else {
      const pol = utils.requestPolicyFileToken(key, policy);
      opt = {
        url: this.urlStr(key),
        headers: {
          'x-authentication': this.options.key,
          'x-authentication-token': pol.token,
          'x-authentication-policy': pol.policy
        }
      };
      return request.del(opt, done);
    }
  }

  head(key, done) {
    debug(`Begin HEAD for key ${key}`);

    const opt =
      {url: this.urlStr(key)};
    return request.head(opt, done);
  }

  // URL Hepler

  url(key) {
    return new UrlRepresentation(this.options.url, this.options.cid, key);
  }

  urlStr(key) {
    return this.url(key).toString();
  }

  // Policy Helper

  policy(date, diff) {
    if (!this.policyFactory) {
      this.policyFactory = new PolicyFactory(this.options.secret);
    }
    return this.policyFactory.represent(date, diff);
  }
}

module.exports = AmagingClient;
