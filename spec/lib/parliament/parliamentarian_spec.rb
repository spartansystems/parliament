require 'spec_helper'

describe Parliament::Parliamentarian do
  before(:each) do
    Parliament.reset_configuration
  end

  context 'Instance Methods' do
    let(:data)            { Hashie::Mash.new(JSON.parse(File.read('spec/fixtures/issue.json'))) }
    let(:parliamentarian) { Parliament::Parliamentarian.new }

    describe '#process' do
      before(:each) do
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:comment_exists?).and_return(true)
        expect_any_instance_of(Parliamentarian::PullRequest).to receive(:comment).and_return(data.comment)
      end

      describe 'when status checking enabled (by default)' do
        it "processes the incoming PR comment and merge, with state==success and score meeting or exceeding threshold" do
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:state).and_return('success')
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:score).and_return(3)
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:merge).and_return(true)
          parliamentarian.process(data)
        end

        it "processes the incoming PR comment but not merge, with state != success" do
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:state).and_return(nil)
          expect_any_instance_of(Parliamentarian::PullRequest).to_not receive(:score)
          expect_any_instance_of(Parliamentarian::PullRequest).to_not receive(:merge)
          parliamentarian.process(data)
        end
      end

      describe 'when status checking disabled' do
        before(:each) do
          Parliament.configure { |config| config.check_status = false }
        end

        it "processes the incoming PR comment and merge, with score meeting or exceeding threshold" do
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:score).and_return(3)
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:merge).and_return(true)
          parliamentarian.process(data)
        end

        it "processes the incoming PR comment but not merge, with score below threshold" do
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:score).and_return(2)
          expect_any_instance_of(Parliamentarian::PullRequest).to_not receive(:merge)
          parliamentarian.process(data)
        end
      end

      describe 'when required_usernames option in use' do
        let(:required) { %w[foo bar baz] }
        before(:each) do
          Parliament.configure { |config| config.required_usernames = required }
        end

        it "processes the incoming PR comment and merge, with score meeting or exceeding threshold and +1 from all required voters" do
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:state).and_return('success')
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:approved_by?).with(required).and_return(true)
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:score).and_return(3)
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:merge).and_return(true)
          parliamentarian.process(data)
        end

        it "processes the incoming PR comment but not merge, without +1 from all reqired voters" do
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:state).and_return('success')
          expect_any_instance_of(Parliamentarian::PullRequest).to receive(:approved_by?).with(required).and_return(false)
          expect_any_instance_of(Parliamentarian::PullRequest).to_not receive(:score)
          expect_any_instance_of(Parliamentarian::PullRequest).to_not receive(:merge)
          parliamentarian.process(data)
        end
      end

      describe "passes data to #required_usernames" do
        before(:each) do
          Parliament.configure { |config| config.check_status = false }
        end
        it "calls #required_usernames with data" do
          expect(parliamentarian).to receive(:required_usernames).with(data).and_return([])
          parliamentarian.process(data)
        end
      end
    end


    describe '#required_usernames' do
      describe 'when configuration.required is left as default empty array' do
        it "returns empty array" do
          parliamentarian.required_usernames(data).should == []
        end
      end

      describe 'when configuration.required is an Array' do
        let(:required) { %w[foo bar baz] }
        before(:each) do
          Parliament.configure { |config| config.required_usernames = required }
        end
        it "returns configuration.required" do
          parliamentarian.required_usernames(data).should == required
        end
      end

      describe 'when configuration.required_usernames is callable (a Proc)' do
        let(:expected_result) { %w[foo bar baz] }
        let(:fake_proc) { stub(:proc) }
        before(:each) do
          Parliament.configure { |config| config.required_usernames = fake_proc }
        end

        it "calls configuration.required_usernames with data and returns result" do
          expect(fake_proc).to receive(:call).with(data).and_return(expected_result)
          parliamentarian.required_usernames(data).should == expected_result
        end
      end
    end

  end # Instance Methods

end
