describe Parliament::PullRequest do
  let(:data)         { Hashie::Mash.new(JSON.parse(File.read('spec/fixtures/issue.json'))) }
  let(:pull_request) { Parliament::PullRequest.new(data) }

  let(:positive_comment) { double :comment, body: "+1 I suppose we should merge this" }
  let(:fake_positive_comment) { double :comment, body: "+ 1 I suppose we should merge this" }
  let(:positive_comment_struckthru) { double :comment, body: "~~+1 awesome~~\nOops - nvm!" }
  let(:negative_comment) { double :comment, body: "-1 This is a bad change.}" }
  let(:fake_negative_comment) { double :comment, body: "- poop This is a bad change." }
  let(:negative_comment_struckthru) { double :comment, body: "~~-1 This is a bad change.~~}" }
  let(:negative_comment_struckthru_and_now_positive) { double :comment, body: "~~-1 This is a bad change.~~Much better +1}" }
  let(:neutral_comment) { double :comment, body: "Who cares?" }
  let(:blocker_comment) { double :comment, body: "[blocker] +1" }
  let(:blocker_comment_caps) { double :comment, body: "[BLOCKER] +1" }
  let(:blocker_comment_struckthru) { double :comment, body: "~~[blocker]~~" }

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

    it "scores a 0 for comment with a +1 inside strikethru markdown" do
      pull_request.send(:comment_score, positive_comment_struckthru).should == 0
    end

    it "scores a 0 for comment with a -1 inside strikethru markdown" do
      pull_request.send(:comment_score, negative_comment_struckthru).should == 0
    end

    it "scores a 1 for comment with a -1 inside strikethru markdown and a +1 outside strikethru markdown" do
      pull_request.send(:comment_score, negative_comment_struckthru_and_now_positive).should == 1
    end

    it "scores a 0 for comment with [blocker]" do
      pull_request.send(:comment_score, blocker_comment).should == 0
    end
  end # single comment score

  context '#has_blocker?' do
    it "returns true when [blocker]" do
      pull_request.send(:has_blocker?, blocker_comment).should == true
    end
    it "returns true when [BLOCKER]" do
      pull_request.send(:has_blocker?, blocker_comment_caps).should == true
    end
    it "returns false when [blocker] is struck thru" do
      pull_request.send(:has_blocker?, blocker_comment_struckthru).should == false
    end
  end

  context 'all comment score' do
    let(:comments_with_blocker) do
      [
        positive_comment,
        positive_comment,
        blocker_comment,
        positive_comment,
        negative_comment,
        neutral_comment,
      ]
    end

    let(:comments_no_blocker) do
      [
        positive_comment,
        positive_comment,
        negative_comment,
        neutral_comment,
        positive_comment,
      ]
    end

    it "totals all comments" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments_no_blocker)
      pull_request.score.should == 2
    end

    it "returns zero if blocker exists" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments_with_blocker)
      pull_request.score.should == 0
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

end
