require 'spec_helper'
require 'rack/test'

describe Parliament::Server do
  include Rack::Test::Methods

  let(:voting_service) { double :voting_service, process: nil }

  def app
    Parliament::Server.new(voting_service)
  end

  it 'is a mountable Rack app' do
    get ''
    expect(last_response.ok?).to be_true
  end

  it 'responds to GETs to /' do
    get '/'
    expect(last_response.ok?).to be_true
  end

  context 'POSTs to /webhook' do
    it 'responds to form data' do
      post '/webhook', "payload" => "{\"foo\":\"bar\"}"
      expect(last_response.ok?).to be_true
    end

    it 'responds to JSON data' do
      post '/webhook', {"payload" => {"foo" => "bar"}}.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.ok?).to be_true
    end

    it 'initiates processing by the voting service' do
      pending
      payload = "{\"foo\":\"bar\"}"
      parsed_payload = JSON.parse(payload)
      post '/webhook', "payload" => payload
      expect(voting_service).to receive(:process).with(parsed_payload)
    end
  end


  it 'returns a 404 for non-root and non-webhook routes' do
    get '/foo'
    expect(last_response.ok?).to be_false
  end

end
