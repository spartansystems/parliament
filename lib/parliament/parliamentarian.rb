require 'octokit'

module Parliament

  class Parliamentarian

    def initialize
      @logger = Logger.new('log/parliamentarian.log', 'daily')
    end

    def process(data)
      @pull_request = PullRequest.new(data)
      if @pull_request.comment_exists?
        log_comment(@pull_request.comment)
        if @pull_request.score > Parliament.configuration.sum
          @pull_request.merge
        end
      end
    end

    private

    def log_comment(comment)
      @logger.info("Comment: '#{comment.body}' from '#{comment.user.login}'")
    end
  end

end
