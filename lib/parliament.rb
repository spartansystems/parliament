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
    attr_accessor :sum
    attr_accessor :status
    attr_accessor :required

    def initialize
      # the sum of +1/-1
      @sum = 3

      # current status must be success
      @status = true

      # an array of required voters' github usernames
      # also accepts an array returning Proc that is called on each check with the raw data from the webhook.
      @required = []
    end
  end
end
include Parliament
