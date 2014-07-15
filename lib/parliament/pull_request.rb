require 'hashie'
require 'github/markdown'

module Parliament

  class PullRequest
    attr_reader :repository
    attr_reader :repository_owner
    attr_reader :pull_request_id
    attr_reader :commit_message

    def initialize(data = {})
      @data             = Hashie::Mash.new(data)
      @repository       = @data.repository.name
      @repository_owner = @data.issue.user.login
      @pull_request_id  = @data.issue.number.to_s
      @commit_message   = @data.issue.title
      @client           = Octokit::Client.new(:netrc => true)
      @repo_string      = "#{@repository_owner}/#{@repository}"
      @logger           = Logger.new('log/parliamentarian.log', 'daily')
    end

    def comment_exists?
      @data.comment.any?
    end

    def comment
      @data.comment
    end

    def score
      total = 0
      comments = @client.issue_comments(@repo_string, @pull_request_id)
      comments.each do |comment|
        body = comment_body_html_strikethrus_removed(comment)
        if has_blocker?(body)
          total = 0
          break
        else
          total += comment_score(body)
        end
      end
      @logger.info("Total Score: #{total}")
      total
    end

    def state
      statuses = @client.statuses(@repo_string, sha)
      statuses.first && statuses.first.state || nil
    end

    def merge
      unless pr.merged?
        @logger.info("Merging Pull Request: #{@pull_request_id} on #{@repo_string}")
        @client.merge_pull_request(@repo_string, @pull_request_id, @commit_message)
      end
    end

    private

    def has_blocker?(comment_body)
      ! /\[blocker\]/i.match(comment_body).nil?
    end

    def sha
      pr.head.sha
    end

    def pr
      @pr ||= @client.pull_request(@repo_string, @pull_request_id)
    end

    def comment_score(comment_body)
      return 1 if /\+\d+/.match(comment_body)
      return -1 if /\-\d+/.match(comment_body)
      0
    end

    def comment_body_html_strikethrus_removed(comment)
      comment_body_html(comment).gsub(/<del>.*?<\/del>/m, '')
    end

    def comment_body_html(comment)
      GitHub::Markdown.render(comment.body)
    end
  end # class PullRequest

end # Parliament
