module Que::Web::Viewmodels
  class RemoteEventList
    extend Forwardable
    attr_reader :events, :pager

    def_delegators :@pager, :total, :next_page, :prev_page, :current_page, :page_count

    def initialize(events, pager = nil)
      @events = events.map { |e| RemoteEvent.new(e) }
      @pager = pager
    end
  end
end
