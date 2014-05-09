require 'spec_helper'

describe Parliament::Parliamentarian do

  context 'Instance Methods' do
    let(:data) { Hashie::Mash.new(JSON.parse(File.read('spec/fixtures/issue.json'))) }
    let(:parliamentarian) do
      p = Parliament::Parliamentarian.new
      p.instance_variable_set(:@data, data)
      p
    end

    describe '#process' do
      it "processes the incoming PR comment" do
        parliamentarian.process(data)
      end
    end

    context 'private methods' do

      context 'single comment score' do
        let(:positive_comment)      { double :comment, body: "+1 I suppose we should merge this" }
        let(:fake_positive_comment) { double :comment, body: "+ 1 I suppose we should merge this" }
        let(:negative_comment)      { double :comment, body: "-1 This is a bad change.}" }
        let(:fake_negative_comment) { double :comment, body: "- poop This is a bad change." }
        let(:neutral_comment)       { double :comment, body: "Who cares?" }
        let(:blocker_comment)       { double :comment, body: "[blocker] +1" }

        it "scores a +1 for comment with a plus sign followed by a number" do
          parliamentarian.send(:comment_score, positive_comment).should == 1
        end

        it "scores a -1 for comment witih a minus sign followed by a number" do
          parliamentarian.send(:comment_score, negative_comment).should == -1
        end

        it "scores a 0 for comment with no +1 or -1" do
          parliamentarian.send(:comment_score, neutral_comment).should == 0
        end

        it "scores a 0 for comment with a plus sign with no number following" do
          parliamentarian.send(:comment_score, fake_positive_comment).should == 0
        end

        it "scores a 0 for comment with a minus sign with no number following" do
          parliamentarian.send(:comment_score, fake_negative_comment).should == 0
        end

        it "scores a 0 for comment with [[bB]locker] with no number following" do
          parliamentarian.send(:comment_score, blocker_comment).should == 0
        end
      end # single comment score

      context 'all comment score' do
        let(:comments) do
          [
            double(:comment, body: "Let's merge: +1"),
            double(:comment, body: "+1 I say merge it"),
            double(:comment, body: "I third the motion: +1"),
            double(:comment, body: "Not me, i think this is stupid: -1"),
            double(:comment, body: "Does anyone really care?"),
            double(:comment, body: " +1 [Blocker]")
          ]
        end

        before(:each) do
          parliamentarian.instance_variable_set(:@client,
                                                double(:client,
                                                       issue_comments: comments))
          parliamentarian.instance_variable_set(:@owner, "midwire")
          parliamentarian.instance_variable_set(:@repository, "parliament")
          parliamentarian.instance_variable_set(:@pull_request_id, "1")
        end

        it "totals all comments" do
          parliamentarian.send(:total_score).should == 2
        end

        it "logs the total score" do
          expect_any_instance_of(Logger).to receive(:info)
          parliamentarian.send(:total_score)
        end
      end # all comment score

      context 'merge_pull_request' do
        it "does not merge if already merged" do
          pending "until we setup this test"
        end

        it "does merge if not already merged" do
          pending "until we setup this test"
        end
      end

      it "returns the current commit message" do
        parliamentarian.send(:commit_message).should == data.issue.title
      end

      it "returns the current pull request id" do
        parliamentarian.send(:pr_number).should == data.issue.number.to_s
      end

      it "returns the current repository name" do
        parliamentarian.send(:repo).should == data.repository.name
      end

      it "returns the current repository owner" do
        parliamentarian.send(:repo_owner).should == data.issue.user.login
      end

    end # private methods
  end # Instance Methods

end
