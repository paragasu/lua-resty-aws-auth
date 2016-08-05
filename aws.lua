-- generate amazon v4 authorization signature
-- https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
-- Author: jeffry L. paragasu@gmail.com
-- Licence: MIT

local _M = { __VERSION = "0.1.0" }
local aws_key, aws_secret, aws_region, aws_service, request
local time = tonumber(ngx.time())
local date = os.date('!%Y%m%d', time),
local timestamp = os.date('!%Y%m%dT%H%M%SZ', time)

-- init new aws auth
local function _M.new(config)
  aws_key     = config.aws_key,
  aws_secret  = config.aws_secret,
  aws_region  = config.aws_region,
  aws_service = config.aws_service,
  request     = config.req 
end


-- get credential
local function get_credential()
  local param = { aws_key, date, aws_region,aws_service, "aws4_request" }
  return table.concat(param, "/")
end


-- get authorization string
-- x-amz-content-sha256 required by s3
local function _M.get_authorization()
  local header = {
    "AWS4-HMAC-SHA256",
    "Credential=" .. get_credential(),
    "SignedHeaders=host;x-amz-content-sha256;x-amz-date",
    "Signature=" .. get_signature()
  }
  return table.concat(header, ", ")
end


-- get the current timestamp in iso8601 basic format
local function _M.get_amz_date()
  return timestamp
end


-- update ngx.request.headers
-- will all the necessary aws required headers
-- for authentication
local function _M.set_ngx_auth_headers()
   
end


return _M
