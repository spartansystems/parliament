require 'octokit'
require 'hashie'

module Parliament

  class Parliamentarian

    def initialize
      @logger          = Logger.new('log/app.log', 'daily')
      @data            = nil
      @repository      = nil
      @owner           = nil
      @pull_request_id = nil
      @client          = nil
    end

    def process(data)
      @data            = Hashie::Mash.new(data)
      @repository      = repo
      @owner           = repo_owner
      @pull_request_id = pr_number
      @client          = Octokit::Client.new(:netrc => true)
      if @data.comment.any?
        log_comment
        if total_score > 2
          merge_pull_request
        end
      end
    end

    private

    def comment_score(comment)
      return 0 if /\[(B|b)locker\]/.match(comment.body)
      return 1 if /\+\d+/.match(comment.body)
      return -1 if /\-\d+/.match(comment.body)
      0
    end

    def total_score
      score = 0
      comments = @client.issue_comments "#{@owner}/#{@repository}", @pull_request_id
      comments.each do |comment|
        score += comment_score(comment)
      end
      @logger.info("Total Score: #{score}")
      score
    end

    def merge_pull_request
      repo_string = "#{@owner}/#{@repository}"
      pr = @client.pull_request repo_string, @pull_request_id
      unless pr.merged?
        @logger.info("Merging Pull Request: #{@pull_request_id} on #{repo_string}")
        @client.merge_pull_request(repo_string, @pull_request_id, commit_message)
      end
    end

    def commit_message
      @data.issue.title
    end

    def pr_number
      @data.issue.number.to_s
    end

    def repo
      @data.repository.name
    end

    def repo_owner
      @data.issue.user.login
    end

    def log_comment
      @logger.info("Comment: '#{@data.comment.body}' from '#{@data.comment.user.login}'")
    end
  end

end
