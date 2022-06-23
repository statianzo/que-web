module Que::Web::Viewmodels
  class Dashboard < Struct.new(:running, :queued, :scheduled, :failing, :errored, :failed)
    def initialize(stats)
      members.each do |m|
        self[m] = stats[m]
      end
    end
  end
end
