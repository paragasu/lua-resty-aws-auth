# lua-resty-aws-auth
Simple lua resty utilities to generate amazon v4 authorization and signature headers.

# Installation

Openresty installation should be compiled with *--with-luajit* directive otherwise you will get an error,

    module 'ffi' not found

Install the package using luarocks

```lua
#luarocks install lua-resty-aws-auth
```

# Usage

```lua

local aws_auth = require "resty.aws-auth"
local config = {
  aws_host       = "email.us-east-1.amazonaws.com",
  aws_key        = "AKIDEXAMPLE",
  aws_secret     = "xxxsecret",
  aws_region     = "us-east-1",
  aws_service    = "ses",
  content_type   = "application/x-www-form-urlencoded",
  request_method = "POST",
  request_path   = "/",
  request_body   = { hello="world" } -- table of all request params
}

local aws = aws_auth:new(config)

-- get the generated authorization header
-- eg: AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request,
---    SignedHeaders=content-type;host;x-amz-date, Signature=xxx
local auth = aws:get_authorization_header()

-- get the x-amz-date header
local amz_date = aws:get_amz_date_header()

```

Add _Authorization_ and _x-amz-date_ header to ngx.req.headers

```lua
aws:set_ngx_auth_headers()

```



Reference
[Signing AWS With Signature V4](https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html)
[AWS service namespaces list](http://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html)
[AWS region and endpoints](http://docs.aws.amazon.com/general/latest/gr/rande.html)
