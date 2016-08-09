package = "lua-resty-aws-auth"
version = "0.08-0"
source = {
   url = "git://github.com/paragasu/lua-resty-aws-auth",
   tag = "v0.01"
}
description = {
   summary  = "Lua utils to calculate AWS signature v4 for authorization",
   homepage = "https://github.com/paragasu/lua-resty-aws-auth",
   license  = "MIT",
   maintainer = "Jeffry L. <paragasu@gmail.com>"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["resty.aws_auth"] = "lib/resty/aws_auth.lua",
   }
}
