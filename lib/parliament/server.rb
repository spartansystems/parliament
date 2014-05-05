require 'json'

module Parliament
  class Server
    attr_reader :parliament_service

    OK_RESPONSE = [200, {"Content-Type" => "text/html"}, ["OK"]]
    NOT_FOUND_RESPONSE = [404, {"Content-Type" => "text/html"}, ["NOT FOUND"]]

    def initialize(parliament_service = Parliamentarian.new)
      @parliament_service = parliament_service
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      if root_request(env)
        OK_RESPONSE
      elsif webhook_post_request(env)
        handle_request(env)
        OK_RESPONSE
      else
        NOT_FOUND_RESPONSE
      end
    end

    private

    def root_request(env)
      /^\/?$/.match(env['PATH_INFO']) && env['REQUEST_METHOD'] == 'GET'
    end

    def webhook_post_request(env)
      /\/webhook/.match(env['PATH_INFO']) && env['REQUEST_METHOD'] == 'POST'
    end

    def handle_request(env)
      parliament_service.process(parsed_data(env))
    end

    def parsed_data(env)
      JSON.parse(data(env))
    end

    def data(env)
      if env["CONTENT_TYPE"] == "application/x-www-form-urlencoded"
        Rack::Request.new(env).params["payload"]
      elsif env["CONTENT_TYPE"] == "application/json"
        env['rack.input'].read
      end
    end

  end
end
