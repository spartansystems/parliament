require 'octokit'

module Parliament

  class Parliamentarian
    def self.process(event)
      new(event).process
    end

    def initialize(event)
      @event  = event
      @logger = Logger.new('log/app.log', 'daily')
    end

    def process(data)
      @repository      = repo(data)
      @owner           = repo_owner(data)
      @pull_request_id = pr_number(data)
      @client          = Octokit::Client.new(:netrc => true)
      if data['comment'].any?
        log_comment(data)
        if total_score(data) > 2
          merge_pull_request(data)
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

    def total_score(data)
      score = 0
      comments = @client.issue_comments "#{@owner}/#{@repository}", @pull_request_id
      comments.each do |comment|
        score += comment_score(comment)
      end
      @logger.info("Total Score: #{score}")
      score
    end

    def merge_pull_request(data)
      repo_string = "#{@owner}/#{@repository}"
      pr = @client.pull_request repo_string, @pull_request_id
      unless pr.merged?
        @logger.info("Merging Pull Request: #{@pull_request_id} on #{repo_string}")
        @client.merge_pull_request(repo_string, @pull_request_id, commit_message(data))
      end
    end

    def commit_message(data)
      data['issue']['body']
    end

    def pr_number(data)
      data['issue']['number'].to_s
    end

    def repo(data)
      data['repository']['name']
    end

    def repo_owner(data)
      data['issue']['user']['login']
    end

    def log_comment(data)
      @logger.info("Comment: '#{data['comment']['body']}' from '#{data['comment']['user']['login']}'")
    end
  end

end
