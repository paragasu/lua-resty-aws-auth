local aws_auth = require 'aws'

local payload = {
    Action = 'sendEmail',
    Source = 'hello@roompillow.com',
    Destination.ToAddress.member.1='paragasu@gmail.com',
    Message.Subject.Data = 'Hello World',
    Message.Body.Text.Data = 'Hello There'
}

local config = {
  aws_key = 'AKIAJRD4IKQHT6O6QSGQ',
  aws_secret = 'AjqZl4wYTyuuQDveeaFcwyCYKQHYaqUYzoFahwtzto8N',
  aws_region = 'us-east-1',
  aws_service = 'email',
  req = payload
}

local aws = aws_auth:mew(config)

print(aws:get_authorization_header())
