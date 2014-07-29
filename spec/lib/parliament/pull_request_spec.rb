describe Parliament::PullRequest do
  let(:data)         { Hashie::Mash.new(JSON.parse(File.read('spec/fixtures/issue.json'))) }
  let(:pull_request) { Parliament::PullRequest.new(data) }

  let(:positive_comment) { "+1 I suppose we should merge this" }
  let(:fake_positive_comment) { "+ 1 I suppose we should merge this" }
  let(:positive_comment_struckthru) { "~~+1 awesome~~\nOops - nvm!" }
  let(:negative_comment) { "-1 This is a bad change.}" }
  let(:fake_negative_comment) { "- poop This is a bad change." }
  let(:negative_comment_struckthru) { "~~-1 This is a bad change.~~}" }
  let(:negative_comment_struckthru_and_now_positive) { "~~-1 This is a bad change.~~Much better +1}" }
  let(:neutral_comment) { "Who cares?" }
  let(:blocker_comment) { "[blocker] +1" }
  let(:blocker_comment_caps) { "[BLOCKER] +1" }
  let(:blocker_comment_struckthru) { "~~[blocker]~~" }

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

    it "scores a -1 for comment with a minus sign followed by a number" do
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
  end # single comment score

  context '#comment_body_html_strikethrus_removed' do
    it 'handles multiple strikethrus non-greedily' do
      comment = double(:comment, body: "Hello ~~World~~ Lorem ipsum ~~dolor sit amet~~ Goodbye")
      pull_request.send(:comment_body_html_strikethrus_removed, comment).should == "<p>Hello  Lorem ipsum  Goodbye</p>\n"
    end
  end

  context '#has_blocker?' do
    it "returns true when [blocker]" do
      pull_request.send(:has_blocker?, blocker_comment).should == true
    end
    it "returns true when [BLOCKER]" do
      pull_request.send(:has_blocker?, blocker_comment_caps).should == true
    end
    it "returns false when no [blocker]" do
      pull_request.send(:has_blocker?, neutral_comment).should == false
    end
  end

  context 'all comment score' do
    it "returns 0 when no comments" do
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return([])
      pull_request.score.should == 0
    end

    it "totals all comment scores" do
      comments = [
          double(:comment, body: blocker_comment_struckthru, user: double(:user, login: 'user1')),
          double(:comment, body: positive_comment, user: double(:user, login: 'user2')),
          double(:comment, body: positive_comment, user: double(:user, login: 'user3')),
          double(:comment, body: negative_comment, user: double(:user, login: 'user4')),
          double(:comment, body: negative_comment, user: double(:user, login: 'user5')),
          double(:comment, body: neutral_comment,  user: double(:user, login: 'user6')),
          double(:comment, body: positive_comment, user: double(:user, login: 'user7')),
          double(:comment, body: positive_comment_struckthru, user: double(:user, login: 'user8')),
          double(:comment, body: negative_comment_struckthru, user: double(:user, login: 'user9')),
          double(:comment, body: negative_comment_struckthru_and_now_positive, user: double(:user, login: 'user10')),
      ]
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments)
      pull_request.score.should == 2
    end

    it "returns zero if blocker exists" do
      comments = [
        double(:comment, body: positive_comment, user: double(:user, login: 'user1')),
        double(:comment, body: positive_comment, user: double(:user, login: 'user2')),
        double(:comment, body: blocker_comment,  user: double(:user, login: 'user3')),
        double(:comment, body: positive_comment, user: double(:user, login: 'user4')),
        double(:comment, body: negative_comment, user: double(:user, login: 'user5')),
        double(:comment, body: neutral_comment,  user: double(:user, login: 'user6')),
      ]
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments)
      pull_request.score.should == 0
    end

    it "only counts last non-neutral comment from a user" do
      comments = [
        double(:comment, body: negative_comment, user: double(:user, login: 'user1')),
        double(:comment, body: negative_comment, user: double(:user, login: 'user1')),
        double(:comment, body: negative_comment, user: double(:user, login: 'user1')),
        double(:comment, body: negative_comment, user: double(:user, login: 'user1')),
        double(:comment, body: positive_comment, user: double(:user, login: 'user1')),
        double(:comment, body: neutral_comment,  user: double(:user, login: 'user1')),
      ]
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments)
      pull_request.score.should == 1
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

  context '#approved_by?' do
    it "returns true when passed an empty array" do
      pull_request.approved_by?([]).should == true
    end

    it "returns true when every username in passed array voted +1" do
      comments = [
        double(:comment, body: positive_comment, user: double(:user, login: 'user1')),
        double(:comment, body: positive_comment, user: double(:user, login: 'user2')),
        double(:comment, body: positive_comment, user: double(:user, login: 'user3')),
        double(:comment, body: negative_comment, user: double(:user, login: 'user4')),
        double(:comment, body: neutral_comment,  user: double(:user, login: 'user5')),
      ]
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments)
      pull_request.approved_by?(%w[user1 user2 user3]).should == true
    end

    it "returns false when at least one username in passed array did not vote +1" do
      comments = [
        double(:comment, body: positive_comment, user: double(:user, login: 'user1')),
        double(:comment, body: positive_comment, user: double(:user, login: 'user2')),
        double(:comment, body: negative_comment, user: double(:user, login: 'user3')),
      ]
      expect_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return(comments)
      pull_request.approved_by?(%w[user1 user2 user3]).should == false
    end
  end

end
