simple-client [![Build Status](https://secure.travis-ci.org/mcrmfc/simple-client.png?branch=master)](http://travis-ci.org/mcrmfc/simple-client) [![Dependency Status](https://gemnasium.com/mcrmfc/simple-client.png)](http://gemnasium.com/mcrmfc/simple-client) 
=============

Uber simple Net::HTTP wrapper for ruby for sole purpose of testing, not a production tool

Features
--------

* Configure client using API or config (via options hash)
* Easy configuration of HTTP Proxy from environment
* Supports no_proxy environment variable
* Easy configuration of ssl (including client certs)

Example usage
--------------

     #using api
     s = SimpleClient::Client.new
     s.request_headers = {'X-Test1'=>'foo', 'X-Test2' => 'bar'}
     s.get 'http://www.foo.co.uk/sport'


     #using api
     s = SimpleClient::Client.new
     response = s.get('http://www.foo.co.uk/sport', 
                      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'})

