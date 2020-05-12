module Que::Web::Viewmodels
  class RemoteEvent < Struct.new(
    :id, :type, :gateway, :data, :meta, :event_order, :remote_event_order, :created_at, :processed_at
  )

    def initialize(job)
      members.each do |m|
        self[m] = job[m]
      end
    end
  end
end
