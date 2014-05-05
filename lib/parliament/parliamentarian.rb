module Parliament
  class Parliamentarian
    def self.process(event)
      new(event).process
    end

    def initialize(event)
      @event = event
    end

    def process

    end
  end
end
