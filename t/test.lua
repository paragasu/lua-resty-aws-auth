-- https://docs.aws.amazon.com/general/latest/gr/samples/aws4_testsuite.zip
local str = require 'resty.string'
local luaunit  = require 'luaunit'
local aws_auth = require 'lib/resty/aws_auth'

local aws = aws_auth:new({
  aws_key = 'AKIDEXAMPLE',
  aws_secret = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
  aws_region = 'us-east-1',
  aws_service = 'iam',
  aws_host = 'email.us-east-1.amazonaws.com', 
  request_body  = {
    Param1 = 'value1',
    Param2 = 'value2'
  }
})

test_aws = {}

-- random time i come up with
aws:set_iso_date(1470764347) 

function test_aws:test_canonical_header()
  local canonical_header = aws:get_canonical_header()
  local expected_header  = 'content-type:application/x-www-form-urlencoded\nhost:email.us-east-1.amazonaws.com\nx-amz-date:20160809T173907Z'
  luaunit.assertEquals(canonical_header, expected_header)
end

function test_aws:test_get_signed_request_body()
  local request_body   = aws:get_signed_request_body()
  local expected_body  = '36e6fb33c956b824c3855578bf2554ed4597a4025b88fbb84b4495b1cba45cd3'
  luaunit.assertEquals(request_body, expected_body)
end

function test_aws:test_get_canonical_request()
  local canonical_request = aws:get_canonical_request()
  luaunit.assertEquals(canonical_request, '5138ee1d1d5617f6759505102e4f1ab97cea3fd53f0741cba89cd9f652f5d1e3')
end

function test_aws:test_signing_key()
  local signing_key = aws:get_signing_key()
  luaunit.assertEquals(str.to_hex(signing_key), 'ed171583b5a52c2f0a2fa41aebdd3374b7bdbd34f672dbc9072a877b7105c5d1')
end

function test_aws:test_get_string_to_sign()
  local string_to_sign  = aws:get_string_to_sign()
  local expected_string = 'AWS4-HMAC-SHA256\n20160809T173907Z\n20160809/us-east-1/iam/aws4_request\n5138ee1d1d5617f6759505102e4f1ab97cea3fd53f0741cba89cd9f652f5d1e3'
  luaunit.assertEquals(string_to_sign, expected_string)
end

function test_aws:test_get_signature()
  local signature = aws:get_signature()
  luaunit.assertEquals(signature, '30eaed16517ac88225f74ccb07b83fc0f9fde1653558420f9c48d88d131b383d')
end

function test_aws:test_get_authorization_header()
  local auth = aws:get_authorization_header()
  local s = 'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20160809/us-east-1/iam/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=30eaed16517ac88225f74ccb07b83fc0f9fde1653558420f9c48d88d131b383d'
  luaunit.assertEquals(auth, s)
end

luaunit.LuaUnit.run()
