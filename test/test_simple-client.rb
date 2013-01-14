require 'rubygems'
require 'bundler/setup'
require 'test/unit'
require 'net/https'
require 'webmock/test_unit'
dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"
require 'simple-client'

class SimpleClient::RequestTest < Test::Unit::TestCase

  def setup
    ENV.clear
  end

  def test_proxy_is_set_correctly_without_no_proxy
    ENV['http_proxy'] = 'http://cache.foo.co.uk:80'
    r = SimpleClient::Request.new
    r.send('prepare_connection', 'http://www.google.co.uk', {}) #test private method
    assert_equal "cache.foo.co.uk", r.instance_variable_get(:@proxy_host)
    assert_equal 80, r.instance_variable_get(:@proxy_port)
  end

  def test_proxy_is_not_set_when_host_in_no_proxy
    ENV['http_proxy'] = 'http://cache.foo.co.uk:80'
    ENV['no_proxy'] = '.google.co.uk'
    r = SimpleClient::Request.new
    r.send('prepare_connection', 'http://www.google.co.uk', {}) #test private method
    assert_equal nil, r.instance_variable_get(:@proxy_host)
    assert_equal nil, r.instance_variable_get(:@proxy_port)
  end

  def test_proxy_is_not_set_when_host_in_no_proxy_and_no_proxy_contains_multiple_hosts
    ENV['http_proxy'] = 'http://cache.foo.co.uk:80'
    ENV['no_proxy'] = '.google.co.uk, foo, localhost'
    r = SimpleClient::Request.new
    r.send('prepare_connection', 'http://localhost/foobar', {}) #test private method
    assert_equal nil, r.instance_variable_get(:@proxy_host)
    assert_equal nil, r.instance_variable_get(:@proxy_port)
  end

end

class SimpleClient::ClientTest < Test::Unit::TestCase

  def setup
    ENV.clear
  end

  def test_simple_get
    #stub
    stub_request(:get, "http://www.foo.co.uk")

    #run
    s = SimpleClient::Client.new
    response = s.get('http://www.foo.co.uk')

    #assert
    assert_requested :get, "http://www.foo.co.uk"
  end

  def test_simple_get_with_query_string
    #stub
    stub_request(:get, "http://www.foo.co.uk").with(:query => {"a" => "b", "c" => "d"})
    #run
    s = SimpleClient::Client.new
    response = s.get('http://www.foo.co.uk?a=b&c=d')

    #assert
    assert_requested :get, "http://www.foo.co.uk?a=b&c=d"
  end

  def test_simple_get_using_ssl
    #stub
    stub_request(:get, "https://www.foo.co.uk")

    #run
    s = SimpleClient::Client.new
    response = s.get('https://www.foo.co.uk')

    #assert
    assert_requested :get, "https://www.foo.co.uk"
  end

  def test_get_with_request_and_response_headers
    #stub
    stub_request(:get, "http://www.foo.co.uk/sport").
      with(:headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :body => "abc", 
                :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    response = s.get('http://www.foo.co.uk/sport', 
                     :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'})

    #assert
    assert_requested :get, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}, :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

  def test_get_with_request_and_response_headers_using_api
    #stub
    stub_request(:get, "http://www.foo.co.uk/sport").
      with(:headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :body => "abc", 
                :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    s.request_headers = {'X-Test1'=>'foo', 'X-Test2' => 'bar'}
    s.get 'http://www.foo.co.uk/sport'

    #assert
    assert_requested :get, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}, :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

  def test_simple_post
    #stub
    stub_request(:post, "http://www.foo.co.uk/sport").with(:body => "abc")

    #run
    s = SimpleClient::Client.new
    response = s.post('http://www.foo.co.uk/sport', :body => 'abc')

    #assert
    assert_requested :post, "http://www.foo.co.uk/sport",
      :body => "abc", :times => 1    # ===> Success
  end

  def test_post_with_request_and_response_headers
    #stub
    stub_request(:post, "http://www.foo.co.uk/sport").
      with(:body => "abc", :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    response = s.post('http://www.foo.co.uk/sport', 
                      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
                      :body => 'abc')


    #assert
    assert_requested :post, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
      :body => "abc", :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end


  def test_post_with_request_and_response_headers_using_api
    #stub
    stub_request(:post, "http://www.foo.co.uk/sport").
      with(:body => "abc", :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    s.request_headers = {'X-Test1'=>'foo', 'X-Test2' => 'bar'}
    s.body = 'abc'
    s.post 'http://www.foo.co.uk/sport'

    #assert
    assert_requested :post, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
      :body => "abc", :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

  def test_post_with_request_and_response_headers_and_setting_x_www_form_urlencoding
    #stub
    stub_request(:post, "http://www.foo.co.uk/sport").
      with(:body => {'foo' => 'bar', 'baz' => 'qux'}, :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    s.post('http://www.foo.co.uk/sport', :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar', 'Content-Type' => 'application/x-www-form-urlencoded'}, :body => { 'foo'=>'bar', 'baz'=>'qux' })

    #assert
    assert_requested :post, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
      :body => "foo=bar&baz=qux", :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

 def test_post_with_request_and_response_header_and_setting_x_www_form_urlencoding_using_api
    #stub
    stub_request(:post, "http://www.foo.co.uk/sport").
      with(:body => {'foo' => 'bar', 'baz' => 'qux'}, :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    s.request_headers = {'X-Test1'=>'foo', 'X-Test2' => 'bar', 'Content-Type' => 'application/x-www-form-urlencoded'}
    s.body = { 'foo'=>'bar', 'baz'=>'qux' } 
    s.post 'http://www.foo.co.uk/sport'

    #assert
    assert_requested :post, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
      :body => "foo=bar&baz=qux", :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

  def test_simple_put
    #stub
    stub_request(:put, "http://www.foo.co.uk/sport").with(:body => "abc")

    #run
    s = SimpleClient::Client.new
    response = s.put('http://www.foo.co.uk/sport', :body => 'abc')

    #assert
    assert_requested :put, "http://www.foo.co.uk/sport",
      :body => "abc", :times => 1    # ===> Success
  end

  def test_put_with_request_and_response_headers
    #stub
    stub_request(:put, "http://www.foo.co.uk/sport").
      with(:body => "abc", :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    response = s.put('http://www.foo.co.uk/sport', 
                     :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
                     :body => 'abc')

    #assert
    assert_requested :put, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'},
      :body => "abc", :times => 1    # ===> Success
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

  def test_simple_delete
    #stub
    stub_request(:delete, "http://www.foo.co.uk/sport")

    #run
    s = SimpleClient::Client.new
    response = s.delete('http://www.foo.co.uk/sport')

    #assert
    assert_requested :delete, "http://www.foo.co.uk/sport"
  end

  def test_delete_with_request_and_response_headers
    #stub
    stub_request(:delete, "http://www.foo.co.uk/sport").
      with(:headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}).
      to_return(:status => 200, :headers => {'Cache-Control' => 'private'})

    #run
    s = SimpleClient::Client.new
    response = s.delete('http://www.foo.co.uk/sport', 
                        :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'})

    #assert
    assert_requested :delete, "http://www.foo.co.uk/sport",
      :headers => {'X-Test1'=>'foo', 'X-Test2' => 'bar'}
    assert_equal({'cache-control' => 'private'}, s.response_headers)
  end

end
