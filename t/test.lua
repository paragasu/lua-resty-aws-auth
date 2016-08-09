-- https://docs.aws.amazon.com/general/latest/gr/samples/aws4_testsuite.zip
local luaunit  = require 'luaunit'
local aws_auth = require 'lib/resty/aws_auth'
local aws = aws_auth:new({
  aws_key = 'AKIDEXAMPLE',
  aws_secret = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
  aws_region = 'us-east-1',
  aws_host = 'email.us-east-1.amazonaws.com', 
  request  = {
    Param1 = 'value1',
    Param2 = 'value2'
  }
})

local date      = '20150830'
local timestamp = '20150830T123600Z'

-- init
test_aws = {}

function test_aws:test_url_encode_request()
  local req = { Param1 = 'value1', Param2 = 'Value2' }
  luaunit.assertEquals(1, true)
  --local request = aws:get_encoded_request(req)
  --luaunit.assertEquals('Param1=value1&Param2=value1', request)
end


function test_aws:test_canonical_header()
  local header = aws:get_canonical_header(headers)
end



function test_aws:test_get_signing_key()
--  local key = aws:get_signing_key(date, 'us-east-1', 'ses')
end

luaunit.LuaUnit.run()
