require 'json'

module Parliament

  class Server
    OK_RESPONSE = [200, {"Content-Type" => "text/html"}, ["OK"]]
    NOT_FOUND_RESPONSE = [404, {"Content-Type" => "text/html"}, ["NOT FOUND"]]

    def initialize(parliament_service = Parliamentarian.new)
      @parliament_service = parliament_service
      @logger = Logger.new('log/server.log', 'daily')
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      if root_request(env)
        OK_RESPONSE
      elsif webhook_post_request(env)
        @logger.info("EventType: #{event_type(env)}")
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

    # Handle the request if it is an 'issue_comment'
    def handle_request(env)
      parliament_service.process(parsed_data(env)) if event_type(env) == 'issue_comment'
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

    def event_type(env)
      env['HTTP_X_GITHUB_EVENT']
    end
  end # Server

end # Parliament
