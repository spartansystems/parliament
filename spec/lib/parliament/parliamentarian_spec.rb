require 'spec_helper'

describe Parliament::Parliamentarian do

  describe '.process' do

    it 'calls #process on an instance' do
      event = :event
      expect_any_instance_of(Parliament::Parliamentarian).to receive(:new).with(event)
      expect_any_instance_of(Parliament::Parliamentarian).to receive(:process)
      Parliament::Parliamentarian.process(event)
    end

  end

  describe '#process' do
    let (:parliamentarian) { Parliament::Parliamentarian.new(:event) }

    parliamentarian.process
  end

end
