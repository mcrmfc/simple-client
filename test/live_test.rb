dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"
require 'simple-client'

s = SimpleClient::Client.new.get 'http://www.google.co.uk'
p s.response_code

s = SimpleClient::Client.new.get 'https://www.google.co.uk'
p s.response_code

s = SimpleClient::Client.new.get('https://repo.dev.bbc.co.uk', :ssl_client_cert => '/etc/pki/certificate.pem')
p s.response_code

s = SimpleClient::Client.new
s.ssl_client_cert = '/etc/pki/certificate.pem'
s.get('https://repo.dev.bbc.co.uk')
p s.response_code
