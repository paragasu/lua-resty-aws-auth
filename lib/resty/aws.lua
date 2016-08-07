-- generate amazon v4 authorization signature
-- https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
-- Author: jeffry L. paragasu@gmail.com
-- Licence: MIT


local hmac   = require 'resty.hmac'
local resty_sha256 = require 'resty.sha256'
local str  = require 'resty.string'
local time = tonumber(ngx.time())
local iso_date = os.date('!%Y%m%d', time)
local iso_tz   = os.date('!%Y%m%dT%H%M%SZ', time)
local aws_key, aws_secret, aws_region, aws_service, aws_host, req_body

local _M = {
  _VERSION = '0.1.0'
}

local mt = { __index = _M }

-- init new aws auth
function _M.new(self, config)
  aws_key     = config.aws_key
  aws_secret  = config.aws_secret
  aws_region  = config.aws_region
  aws_service = config.aws_service
  aws_host    = config.aws_host
  req_body    = config.request_body
  return setmetatable(_M, mt)
end

-- create canonical headers
-- header must be sorted asc 
function _M.get_canonical_header(self)
  local h = {
    'content-type:application/x-www-form-urlencoded',
    'host:' .. aws_host,
    'x-amz-date:' .. iso_tz
  }
  return table.concat(h, '\n')
end


function _M.get_signed_request_body(self)
  table.sort(req_body)
  local params = ngx.encode_args(req_body)
  local digest = self:get_sha256_digest(params or '')
  return string.lower(digest) -- hash must be in lowercase hex string
end


-- get canonical request 
-- https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
function _M.get_canonical_request(self)
  local signed_header = 'content-type;host;x-amz-date'
  local canonical_header = self:get_canonical_header()
  local signed_body = self:get_signed_request_body()
  local param  = {
    'POST',
    '/',  -- canonical url is / for post
    '', -- canonical querystr
    canonical_header,
    '',   -- required
    signed_header, 
    signed_body
  } 
  local canonical_request = table.concat(param, '\n')      
  return self:get_sha256_digest(canonical_request)
end


-- generate sha256 from the given string
function _M.get_sha256_digest(self, s)
  local h = resty_sha256:new()
  h:update(s)
  return str.to_hex(h:final())
end


function _M.hmac(self, secret, message)
  local  h = hmac:new('AWS4' .. aws_secret, hmac.ALGOS.SHA256)
  return h:final(message, false)
end

-- get signing key
-- https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
function _M.get_signing_key(self)
  local  k_date    = self:hmac('AWS4' .. aws_secret, iso_date)
  local  k_region  = self:hmac(k_date, aws_region)
  local  k_service = self:hmac(k_region, aws_service)
  return self:hmac(k_service, 'aws4_request')
end


-- build aws credential
function _M.get_credential()
  local  param = { aws_key, iso_date, aws_region, aws_service, 'aws4_request' }
  return table.concat(param, '/') 
end


-- get string
function _M.get_string_to_sign(self)
  local param = { iso_date, aws_region, aws_service, 'aws4_request' }
  local cred  = table.concat(param, '/')
  local req   = self:get_canonical_request()
  return table.concat({ 'AWS-HMAC-SHA256', iso_tz, cred, req}, '\n')
end


-- generate signature
function _M.get_signature(self)
  local  signing_key = self:get_signing_key()
  local  string_to_sign = self:get_string_to_sign() 
  return str.to_hex(self:hmac(signing_key, string_to_sign))
end


-- get authorization string
-- x-amz-content-sha256 required by s3
function _M.get_authorization_header(self)
  local signed_header =  'content-type;host;x-amz-date'
  local header = {
    'AWS4-HMAC-SHA256',
    'Credential=' .. self:get_credential(),
    'SignedHeaders=' .. signed_header,
    'Signature=' .. self:get_signature()
  }
  return table.concat(header, ', ')
end


-- get the current timestamp in iso8601 basic format
function _M.get_date_header()
  return iso_tz
end


-- update ngx.request.headers
-- will all the necessary aws required headers
-- for authentication
function _M.set_ngx_auth_headers(self)
  ngx.req.set_header('Authorization', self.get_authorization_header())
  ngx.req.set_header('X-Amz-Date', timestamp) 
end


return _M
