module Que::Web::Viewmodels
  class EventList
    extend Forwardable
    attr_reader :events, :pager

    def_delegators :@pager, :total, :next_page, :prev_page, :current_page, :page_count

    def initialize(events, pager)
      @events = events.map { |e| Event.new(e) }
      @pager = pager
    end
  end
end
