# lua-resty-aws-auth
simple lua resty utilities to generate amazon v4 authorization and signature headers

# usage

    $luarocks install lua-resty-aws-auth


# Usage

```lua

local aws_auth = require "lua-resty-aws-auth"
local config = {
  aws_key = "",
  aws_secret = "",
  region  = "",
  service = "",
  req = "" -- table of all request params
}

local aws = aws_auth:new(config)

-- get the generated authorization header
local auth = aws:get_authorization()

```

Add _Authorization_ and _x-amz-date_ header to ngx.req.headers

```lua
aws:set_ngx_auth_headers()

```


Reference 
[Signing AWS With Signature V4](https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html)
