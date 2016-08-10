package = "lua-resty-aws-auth"
version = "0.01-0"
source = {
   url = "git://github.com/paragasu/lua-resty-aws-auth",
   tag = "v0.01-0"
}
description = {
   summary  = "Lua resty module to calculate AWS signature v4 authorization header",
   homepage = "https://github.com/paragasu/lua-resty-aws-auth",
   license  = "MIT",
   maintainer = "Jeffry L. <paragasu@gmail.com>"
}
dependencies = {
   "lua >= 5.1",
   "lua-erento-hmac",
   "lua-resty-string"
}
build = {
   type = "builtin",
   modules = {
      ["resty.aws_auth"] = "lib/resty/aws_auth.lua",
   }
}
