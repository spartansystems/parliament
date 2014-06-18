describe Parliament::PullRequest do
  let(:data)         { Hashie::Mash.new(JSON.parse(File.read('spec/fixtures/issue.json'))) }
  let(:pull_request) { Parliament::PullRequest.new(data) }

  context '#comment_exists?' do
    it "returns true if a comment exists" do
      pull_request.comment_exists?.should == true
    end

    it "returns false if a comment does not exist" do
      expect_any_instance_of(Hashie::Mash).to receive(:comment).and_return({})
      pull_request.comment_exists?.should == false
    end
  end

  context '#comment' do
    it "returns the current comment" do
      comment = pull_request.comment
      comment.should be_a Hash
      comment.body.should == data.comment.body
    end
  end

  context 'single comment score' do
    let(:positive_comment)      { double :comment, body: "+1 I suppose we should merge this" }
    let(:fake_positive_comment) { double :comment, body: "+ 1 I suppose we should merge this" }
    let(:negative_comment)      { double :comment, body: "-1 This is a bad change.}" }
    let(:fake_negative_comment) { double :comment, body: "- poop This is a bad change." }
    let(:neutral_comment)       { double :comment, body: "Who cares?" }
    let(:blocker_comment)       { double :comment, body: "[blocker] +1" }

    it "scores a +1 for comment with a plus sign followed by a number" do
      pull_request.send(:comment_score, positive_comment).should == 1
    end

    it "scores a -1 for comment witih a minus sign followed by a number" do
      pull_request.send(:comment_score, negative_comment).should == -1
    end

    it "scores a 0 for comment with no +1 or -1" do
      pull_request.send(:comment_score, neutral_comment).should == 0
    end

    it "scores a 0 for comment with a plus sign with no number following" do
      pull_request.send(:comment_score, fake_positive_comment).should == 0
    end

    it "scores a 0 for comment with a minus sign with no number following" do
      pull_request.send(:comment_score, fake_negative_comment).should == 0
    end

    it "scores a 0 for comment with [[bB]locker] with no number following" do
      pull_request.send(:comment_score, blocker_comment).should == 0
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

    it "totals all comments" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments)
      pull_request.score.should == 2
    end

    it "logs the total score" do
      expect_any_instance_of(Logger).to receive(:info)
      pull_request.score
    end
  end # all comment score

  context 'merge_pull_request' do
    it "does not merge if already merged" do
      pr = double(:pull_request, :merged? => true)
      expect_any_instance_of(Octokit::Client).to receive(:pull_request).and_return(pr)
      expect_any_instance_of(Octokit::Client).to_not receive(:merge_pull_request)
      pull_request.merge
    end

    it "does merge if not already merged" do
      pr = double(:pull_request, :merged? => false)
      expect_any_instance_of(Octokit::Client).to receive(:pull_request).and_return(pr)
      expect_any_instance_of(Octokit::Client).to receive(:merge_pull_request)
      pull_request.merge
    end
  end

  context '#state' do
    it "returns nil when no statuses" do
      expect_any_instance_of(Octokit::Client).to receive(:statuses).and_return([])
      pull_request.state.should == nil
    end

    it "returns state of first status" do
      statuses = [
        double(:status, state: 'foo'),
        double(:status, state: 'bar')
      ]
      expect_any_instance_of(Octokit::Client).to receive(:statuses).and_return(statuses)
      pull_request.state.should == 'foo'
    end
  end

end
