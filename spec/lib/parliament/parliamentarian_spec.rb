require 'spec_helper'

describe Parliament::Parliamentarian do

  context 'Instance Methods' do
    let(:data)            { Hashie::Mash.new(JSON.parse(File.read('spec/fixtures/issue.json'))) }
    let(:parliamentarian) { Parliament::Parliamentarian.new }

    describe '#process' do
      before(:each) do
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:comment_exists?).and_return(true)
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:comment).and_return(data.comment)
      end

      it "processes the incoming PR comment and merge, with score meeting or exceeding threshold" do
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:score).and_return(4)
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:merge).and_return(true)
        parliamentarian.process(data)
      end

      it "processes the incoming PR comment but not merge, with score below threshold" do
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:score).and_return(3)
        expect_any_instance_of(Parliamentarian::PullRequest).to_not receive(:merge)
        parliamentarian.process(data)
      end
    end

  end # Instance Methods

end
