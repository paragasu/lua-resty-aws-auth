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
  req = ""
}
local aws = aws_auth:new(config)
local auth = aws:get_authorization()

```

Set the ngx env variable

```lua
aws:set_ngx_auth_headers()

```
