module Que::Web::Viewmodels
  class Event < Struct.new(
    :id, :type, :data, :metadata, :event_order, :processed, :created_at, :processed_at
  )

    def initialize(job)
      members.each do |m|
        self[m] = job[m]
      end
    end
  end
end
