module Que::Web::Viewmodels
  class EventDashboard < Struct.new(:total, :remote)
    def initialize(stats)
      members.each do |m|
        self[m] = stats[m]
      end
    end
  end
end
