require 'logger'

require 'parliament/pull_request'
require 'parliament/parliamentarian'
require 'parliament/server'
require 'parliament/version'

module Parliament
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset_configuration
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :threshold
    attr_accessor :check_status
    attr_accessor :required_usernames

    def initialize
      @threshold = 3
      @check_status = true
      @required_usernames = []
    end
  end
end
include Parliament
