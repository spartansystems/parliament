require 'spec_helper'

describe Parliament::Server do

  let(:voting_service) { double :voting_service, process: nil }

  def app
    @app ||= Parliament::Server.new(voting_service)
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
    before(:each) do
      current_session.header('X_GITHUB_EVENT', 'issue_comment')
    end

    it 'responds to form data' do
      post '/webhook', "payload" => "{\"foo\":\"bar\"}"
      expect(last_response.ok?).to be_true
    end

    it 'responds to JSON data' do
      current_session.header('CONTENT_TYPE', 'application/json')
      post '/webhook', {"payload" => {"foo" => "bar"}}.to_json, "CONTENT_TYPE" => "application/json"
      expect(last_response.ok?).to be_true
    end

    it 'initiates processing by the voting service' do
      payload = File.read('spec/fixtures/issue.json')
      parsed_payload = JSON.parse(payload)
      expect(voting_service).to receive(:process)
      post '/webhook', "payload" => payload
    end
  end

  it 'returns a 404 for non-root and non-webhook routes' do
    get '/foo'
    expect(last_response.ok?).to be_false
  end

end
