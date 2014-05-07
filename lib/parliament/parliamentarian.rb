require 'github_api'

module Parliament

  class Parliamentarian
    def self.process(event)
      new(event).process
    end

    def initialize(event)
      @event = event
      @logger = Logger.new('log/app.log', 'daily')
    end

    def process(data)
      if data['comment'].any?
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
      github = Github.new
      score = 0
      github.issues.comments.list(repo_owner(data),
                                  repo(data),
                                  request_id: pr_number(data) ) do |comment|
        score += comment_score(comment)
      end
      score
    end

    def merge_pull_request(data)
      owner = repo_owner(data)
      repo = repo(data)
      id = pr_number(data)
      github = Github.new(login: 'midwire', password: "N*ibtM*Vb7AjFppE8uEE")
      unless github.pull_requests.merged?(owner, repo, id)
        @logger.info("Merging Pull Request: #{id} on #{owner}/#{repo}")
        github.pull_requests.merge(owner, repo, id)
      end
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
  end

end
