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

local iso_date, iso_tz = aws:get_iso_date()

print(iso_date, iso_tz)

-- init
test_aws = {}

function test_aws:test_url_encode_request()
  local canonical_header = aws:get_canonical_header()
  local expected_header  = 'content-type:application/x-www-form-urlencoded\nhost:email.us-east-1.amazonaws.com\nx-amz-date:' .. iso_tz
  luaunit.assertEquals(canonical_header, expected_header)
end


function test_aws:test_canonical_header()
  local header = aws:get_canonical_header(headers)
end



function test_aws:test_get_signing_key()
--  local key = aws:get_signing_key(date, 'us-east-1', 'ses')
end

luaunit.LuaUnit.run()
