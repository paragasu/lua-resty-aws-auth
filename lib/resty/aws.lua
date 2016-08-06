-- generate amazon v4 authorization signature
-- https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
-- Author: jeffry L. paragasu@gmail.com
-- Licence: MIT


local resty_hmac   = require 'resty.hmac'
local resty_sha256 = require 'resty.sha256'
local str  = require 'resty.string'
local time = tonumber(ngx.time())
local iso_date = os.date('!%Y%m%d', time)
local iso_tz   = os.date('!%Y%m%dT%H%M%SZ', time)
local aws_key, aws_secret, aws_region, aws_service, aws_host, req_body

-- init new aws auth
local function new(config)
  aws_key     = config.aws_key
  aws_secret  = config.aws_secret
  aws_region  = config.aws_region
  aws_service = config.aws_service
  aws_host    = config.aws_host
  req_body    = config.request_body
end


-- create canonical headers
-- header must be sorted asc 
local function get_canonical_headers()
  local h = {
    'content-type:application/x-www-form-urlencoded',
    'host:' .. aws_host,
    'x-amz-date:' .. iso_tz
  }
  return table.concat(h, '\n')
end


local function get_signed_request_body()
  table.sort(req_body)
  local params = ngx.encode_args(req_body)
  local digest = get_sha256_digest(params or '')
  return string.lower(digest) -- hash must be in lowercase hex string
end


-- get canonical request 
-- https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
local function get_canonical_request()
  local param  = {
    'POST\n',
    '/\n', -- canonical url is / for post
    '\n',  -- canonical query string empty because we only support post
    'content-type:application/x-www-form-urlencoded',
    get_canonical_header(),
    'content-type;host;x-amz-date\n' --signed header
    get_signed_request_body()
  } 
  
  local canonical_request = table.concat(param, '\n')      
  return get_sha256_digest(canonical_request)
end


-- get signing key
-- https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
local function get_signing_key(date, region, service)
  local h = resty_hmac:new()
  local k_date = h:digest('sha256', 'AWS4' .. date, true)
  local k_region = h:digest('sha256', k_date, region, true)
  local k_service = h:digest('sha256', k_region, service, true)
  return h:digest('sha256', k_service, 'aws4_request', true)
end


-- generate sha256 from the given string
local function get_sha256_digest(s)
  local h = resty_sha256:new()
  h:update(s)
  return str.to_hex(h:final())
end

-- build aws credential
local function get_credential()
  local param = { aws_key, date, aws_region, aws_service, 'aws4_request' }
  return table.concat(param, '/') 
end


-- get string
local function get_string_to_sign()
  local content = {
    'AWS4-HMAC-SHA256',
    timestamp,
    get_credential(),
    get_canonical_request()
  }
  return table.concat(content, '\n')
end


-- generate signature
local function get_signature()
  local h = resty_hmac:new()
  local signing_key = get_signing_key(date, aws_region, aws_service)
  local string_to_sign = get_string_to_sign() 
  return h:digest('sha256', signing_key, string_to_sign, false)
end


-- get authorization string
-- x-amz-content-sha256 required by s3
local function get_authorization_header()
  local header = {
    'AWS4-HMAC-SHA256',
    'Credential=' .. get_credential(),
    'SignedHeaders=host;content-type;x-amz-date',
    'Signature=' .. get_signature()
  }
  return table.concat(header, ', ')
end


-- get the current timestamp in iso8601 basic format
local function get_amz_date_header()
  return timestamp
end


-- update ngx.request.headers
-- will all the necessary aws required headers
-- for authentication
local function set_ngx_auth_headers()
  ngx.req.set_header('Authorization', get_authorization())
  ngx.req.set_header('X-Amz-Date', timestamp) 
end


return {
  __VERSION = '0.1.0',
  new = new,
  get_encoded_request = get_encoded_request,
  get_amz_date_header = get_amz_date_header,
  get_authorization_header = get_authorization_header,
  set_ngx_auth_headers = set_ngx_auth_headers 
}
