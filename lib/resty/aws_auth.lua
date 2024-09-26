-- generate amazon v4 authorization signature
-- https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
-- Author: jeffry L. paragasu@gmail.com
-- Licence: MIT


local resty_digest = require "resty.digest"
local str = require "resty.utils.string"
local aws_key, aws_secret, aws_region, aws_service, aws_host, aws_stoken
local iso_date, iso_tz, cont_type, req_method, req_path, req_body, req_querystr

local _M = {
  _VERSION = '0.2.0'
}

local mt = { __index = _M }

-- init new aws auth
function _M.new(self, config)
  aws_key     = config.aws_key
  aws_secret  = config.aws_secret
  aws_stoken  = config.aws_secret_token 
  aws_region  = config.aws_region
  aws_service = config.aws_service
  aws_host    = config.aws_host
  cont_type   = config.content_type
  req_method  = config.request_method or "POST"
  req_path    = config.request_path   or "/"
  req_body    = config.request_body
  req_querystr = config.request_querystr or ""
  
  -- set default time
  self:set_iso_date(ngx.time())
  return setmetatable(_M, mt)
end


-- required for testing
function _M.set_iso_date(self, microtime)
  iso_date = os.date('!%Y%m%d', microtime)
  iso_tz   = os.date('!%Y%m%dT%H%M%SZ', microtime)
end


-- create canonical headers
-- header must be sorted asc
function _M.get_canonical_header(self)
  local h = {}

  if cont_type and cont_type ~= "" then
    table.insert(h, "content-type:" .. cont_type)
  end

  table.insert(h, "host:" .. aws_host)

  -- The x-amz-content-sha256 header is required for Amazon S3 AWS requests. It provides a hash of
  -- the request payload. If there is no payload, you must provide the hash of an empty string.
  if aws_service:sub(1,2) == "s3" then
    table.insert(h, "x-amz-content-sha256:" .. self:get_signed_request_body())
  end

  table.insert(h, "x-amz-date:" .. iso_tz)

  if aws_stoken and aws_stoken ~= "" then
    table.insert(h, "x-amz-security-token:" .. aws_stoken)
  end

  return table.concat(h, '\n')
end


function _M.get_signed_request_body(self)
  local params = req_body
  if type(req_body) == 'table' then
    table.sort(params)
    params = ngx.encode_args(params)
  end
  local digest = self:get_sha256_digest(params or '')
  return string.lower(digest) -- hash must be in lowercase hex string
end


-- get canonical request
-- https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
function _M.get_canonical_request(self)
  local signed_header = self:get_signed_header()
  local canonical_header = self:get_canonical_header()
  local canonical_querystr = self:get_canonical_query_string()
  local signed_body = self:get_signed_request_body()
  local param  = {
    req_method,
    req_path,
    canonical_querystr,
    canonical_header,
    '',   -- required
    signed_header,
    signed_body
  }
  local canonical_request = table.concat(param, '\n')
  ngx.log(ngx.INFO, "canonical_request: ", canonical_request)
  return self:get_sha256_digest(canonical_request)
end


-- generate sha256 from the given string
function _M.get_sha256_digest(self, s)
  local h = resty_digest.new("sha256")
  h:update(s)
  return str.tohex(h:final())
end


function _M.hmac(self, secret, message)
  ngx.log(ngx.INFO, "secret: ", secret)
  ngx.log(ngx.INFO, "message: ", message)
  local h = resty_digest.new("sha256", secret)
  h:update(message)
  local s = h:final()
  h:reset()
  return s
end


-- get signing key
-- https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
function _M.get_signing_key(self)
  local  k_date    = self:hmac('AWS4' .. aws_secret, iso_date)
  local  k_region  = self:hmac(k_date, aws_region)
  local  k_service = self:hmac(k_region, aws_service)
  local  k_signing = self:hmac(k_service, 'aws4_request')
  return k_signing
end


-- get string
function _M.get_string_to_sign(self)
  local param = { iso_date, aws_region, aws_service, 'aws4_request' }
  local cred  = table.concat(param, '/')
  local req   = self:get_canonical_request()
  return table.concat({ 'AWS4-HMAC-SHA256', iso_tz, cred, req}, '\n')
end


-- generate signature
function _M.get_signature(self)
  local  signing_key = self:get_signing_key()
  local  string_to_sign = self:get_string_to_sign()
  ngx.log(ngx.INFO, "string_to_sign: ", string_to_sign)
  ngx.log(ngx.INFO, "signing_key: ", signing_key)
  return str.tohex(self:hmac(signing_key, string_to_sign))
end


-- get authorization string
-- x-amz-content-sha256 required by s3
function _M.get_authorization_header(self)
  local  param = { aws_key, iso_date, aws_region, aws_service, 'aws4_request' }
  local header = {
    'AWS4-HMAC-SHA256 Credential=' .. table.concat(param, '/'),
    'SignedHeaders=' .. self:get_signed_header(),
    'Signature=' .. self:get_signature()
  }
  return table.concat(header, ', ')
end


-- update ngx.request.headers
-- will all the necessary aws required headers
-- for authentication
function _M.set_ngx_auth_headers(self)
  ngx.req.set_header('Authorization', self:get_authorization_header())
  ngx.req.set_header('X-Amz-Date', iso_tz)
  ngx.req.set_header("host", aws_host) 
  ngx.req.set_header("content-type", cont_type) 
  if aws_service:sub(1,2) == "s3" then
    ngx.req.set_header("X-Amz-Content-SHA256", self:get_signed_request_body())
  end

  if aws_stoken and aws_stoken ~= "" then
    ngx.req.set_header('X-Amz-Security-Token', aws_stoken)
  end
end


-- get the current timestamp in iso8601 basic format
function _M.get_date_header()
  return iso_tz
end

-- create canonical headers
-- header must be sorted asc
function _M.get_signed_header(self)
  local signed_header = {}

  if cont_type and cont_type ~= "" then
    table.insert(signed_header, "content-type")
  end

  table.insert(signed_header, "host")

  if aws_service:sub(1,2) == "s3" then
    table.insert(signed_header, "x-amz-content-sha256")
  end

  table.insert(signed_header, "x-amz-date")

  if aws_stoken and aws_stoken ~= "" then
    table.insert(signed_header, "x-amz-security-token")
  end


  return table.concat(signed_header, ";")
end


-- encode query string using URI encode rules
-- see UriEncode @ https://docs.aws.amazon.com/IAM/latest/UserGuide/create-signed-request.html
function _M.encode_querystr(self, querystr)
  local q = {}
  local i = 1
  local length = #querystr

  while i <= length do
    local c = querystr:sub(i, i)

    if c:match("[A-Za-z0-9%-%.%_%~=&]") then
      table.insert(q, c)
    elseif c == " " then
      table.insert(q, "%20")
    elseif c == "%" then
      if i + 2 <= length then
        local digit1 = querystr:sub(i+1, i+1)
        local digit2 = querystr:sub(i+2, i+2)

        if digit1:match("[0-9A-F]") and digit2:match("[0-9A-F]") then
          table.insert(q, "%" .. digit1 .. digit2)
          i = i + 2
        else
          table.insert(q, c)
        end

      end
    else
      table.insert(q, string.format("%%%02X", string.byte(c)))
    end

    i = i + 1
  end

  return table.concat(q)
end


-- create canoncial query string
-- query string must be sorted by parameter name asc
function _M.get_canonical_query_string(self)
  local encoded = self:encode_querystr(req_querystr)
  ngx.log(ngx.DEBUG, "encoded = " .. encoded)
  local parsed = {}
  for key, value in string.gmatch(encoded, "([^&=?]+)=?([^&=?]*)") do
    parsed[key] = value
  end
  ngx.log(ngx.DEBUG, "parsed = " .. table.concat(parsed, '|'))
  local sorted_keys = {}
  for key in pairs(parsed) do
    table.insert(sorted_keys, key)
  end
  table.sort(sorted_keys)

  local sorted = {}
  for _, key in ipairs(sorted_keys) do
    local value = parsed[key]
    if value == "" then
      table.insert(sorted, key .. "=")
    else
      table.insert(sorted, key .. "=" .. value)
    end
  end

  return table.concat(sorted, "&")
end

return _M
