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
        if ok_to_merge?(@pull_request, data)
          @pull_request.merge
        end
      end
    end

    def required_usernames(data)
      required = Parliament.configuration.required
      if required.respond_to?(:call)
        required.call(data)
      else
        required
      end
    end

    private

    def ok_to_merge?(pull_request, data)
      if Parliament.configuration.status
        return false unless pull_request.state == 'success'
      end
      return false unless pull_request.approved_by?(required_usernames(data))
      pull_request.score > Parliament.configuration.sum
    end

    def log_comment(comment)
      @logger.info("Comment: '#{comment.body}' from '#{comment.user.login}'")
    end
  end

end
