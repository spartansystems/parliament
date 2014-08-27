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
          @logger.info("Ok to merge")
          @pull_request.merge
        else
          @logger.info("Not ok to merge")
        end
      end
    end

    def required_usernames(data)
      required = Parliament.configuration.required_usernames
      if required.respond_to?(:call)
        required.call(data)
      else
        required
      end
    end

    private

    def ok_to_merge?(pull_request, data)
      status_ok?(pull_request) &&
      required_users_ok?(pull_request, data) &&
      score_ok?(pull_request)
    end

    def status_ok?(pull_request)
      if Parliament.configuration.check_status
        pull_request.state == 'success'
      else
        true
      end
    end

    def required_users_ok?(pull_request, data)
      pull_request.approved_by?(required_usernames(data))
    end

    def score_ok?(pull_request)
      pull_request.score >= Parliament.configuration.threshold
    end

    def log_comment(comment)
      @logger.info("Comment: '#{comment.body}' from '#{comment.user.login}'")
    end
  end

end
