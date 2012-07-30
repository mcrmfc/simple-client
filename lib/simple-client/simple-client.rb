require 'net/https'
require 'uri'

module SimpleClient

  class Client
    attr_reader :response, :response_headers, :response_code, :response_body
    attr_accessor :ssl_client_cert, :request_headers, :body

    def initialize
      @response = nil
      @response_headers = {}
    end

    ##
    # Wrapper for Net::HTTP Get
    #
    # @param [String] url   The full request URL
    # @param [Hash] params  Optional parameters format e.g. {:headers => 
    # {'X-Foo' => 'bar, 'User-Agent' => 'Firefox'}}
    #
    # @return [SimpleClient::Client] Instance of self for chaining
    def get(url, params = {})
      get = GetRequest.new
      do_request(get, url, params)
    end

    ##
    # Wrapper for Net::HTTP Post
    #
    # @param [String] url   The full request URL
    # @param [Hash] params  Optional parameters format e.g. {:headers => 
    # {'X-Foo' => 'bar, 'User-Agent' => 'Firefox'}, :body => 'abc'}
    #
    # @return [SimpleClient::Client] Instance of self for chaining
    def post(url, params = {})
      post = PostRequest.new
      do_request(post, url, params)
    end

    ##
    # Wrapper for Net::HTTP Put
    #
    # @param [String] url   The full request URL
    # @param [Hash] params  Optional parameters format e.g. {:headers => 
    # {'X-Foo' => 'bar, 'User-Agent' => 'Firefox'}, :body => 'abc'}
    #
    # @return [SimpleClient::Client] Instance of self for chaining
    def put(url, params = {})
      put = PutRequest.new
      do_request(put, url, params)
    end

    ##
    # Wrapper for Net::HTTP Delete
    #
    # @param [String] url   The full request URL
    # @param [Hash] params  Optional parameters format e.g. {:headers => 
    # {'X-Foo' => 'bar, 'User-Agent' => 'Firefox'}}
    #
    # @return [SimpleClient::Client] Instance of self for chaining
    def delete(url, params = {})
      delete = DeleteRequest.new
      do_request(delete, url, params)
    end

    private

    def do_request(http, url, params)
      convert_api_to_hash(params)
      @response = http.request(url, params)
      store_response_data
      self
    end

    def store_response_data
      set_response_headers
      @response_code = @response.code
      @response_body = @response.body
    end

    def set_response_headers
      @response.each_header do |h, v|
        @response_headers[h] = v
      end
    end

    def convert_api_to_hash(params)
      params[:ssl_client_cert] = @ssl_client_cert if @ssl_client_cert
      params[:headers] = @request_headers if @request_headers
      params[:body] = @body if @body
    end

  end

  class Request

    def initialize
      @proxy_host = nil
      @proxy_port = nil
    end

    ##
    # Base class for a HTTP Request - intended for subclassing
    #
    # @param [String] url   The full request URL
    # @param [Hash] params  Optional parameters format e.g. {:headers => 
    # {'X-Foo' => 'bar, 'User-Agent' => 'Firefox'}}
    #
    # @return [Net::HTTPResponse] Net::HTTP Response object
    def request(url, params)
      connection = prepare_connection(url, params)
      req = create_request(params[:body])
      do_request(req, params[:headers], connection)
    end

    private

    def prepare_connection(url, params)
      @parts = get_uri_parts_from url
      set_proxy
      connection = get_connection(@parts[:host], @parts[:port], params)
    end

    def do_request(req, headers, connection)
      add_headers(req, headers)
      connection.request req
    end

    def create_request(body)
      raise "Not supported in base class"
    end


    def add_headers(request, headers)
      headers.each do |header,value|
        request.add_field(header, value)
      end if headers
    end

    def set_proxy
      proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
      if proxy && !no_proxy_host?(@parts[:host])
        parts = get_uri_parts_from proxy if proxy
        @proxy_host = parts[:host] 
        @proxy_port = parts[:port] 
      end
    end

    def no_proxy_host?(host)
      no_proxy = ENV['no_proxy'] || ENV['NO_PROXY']
      proxy_host = []
      if no_proxy
       no_proxy_hosts = no_proxy.split(',')
       no_proxy_hosts.map { |h| h.strip! }
       proxy_host = no_proxy_hosts.map {|h| host.include? h}
      end
      proxy_host.include? true
    end

    def get_connection(host, port, params)
      http = Net::HTTP::Proxy(@proxy_host, @proxy_port).new(host,port)
      configure_ssl(http, params)
      http
    end

    def configure_ssl(http, params)
      http.use_ssl = true if (@parts[:scheme] == 'https')
      if params[:ssl_client_cert]
        pem = File.read(params[:ssl_client_cert])
        http.cert = OpenSSL::X509::Certificate.new(pem)
        http.key = OpenSSL::PKey::RSA.new(pem)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def get_uri_parts_from(base)
      uri = URI.parse(base)
      parts = {:scheme => uri.scheme, :host => uri.host,
        :port => uri.port, :path => uri.path, :query => uri.query,
        :fragment => uri.fragment}
      parts[:path] = '/' if uri.path.empty?
      parts
    end

  end

  class GetRequest < Request

    protected 

    def create_request(body)
      query = @parts[:query] ? "?#{@parts[:query]}" : ""
      Net::HTTP::Get.new(@parts[:path] + query)
    end
  end

  class PostRequest < Request

    protected 

    def create_request(body)
      post = Net::HTTP::Post.new(@parts[:path])
      post.body = body
      post
    end
  end

  class PutRequest < Request

    protected 

    def create_request(body)
      put = Net::HTTP::Put.new(@parts[:path])
      put.body = body
      put
    end
  end

  class DeleteRequest < Request

    protected 

    def create_request(body)
      Net::HTTP::Delete.new(@parts[:path])
    end
  end

end
