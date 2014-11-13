module Que::Web::Viewmodels
  class JobList
    extend Forwardable
    attr_reader :page_jobs, :pager

    def_delegators :@pager, :total, :next_page, :prev_page, :current_page, :page_count

    def initialize(page_jobs, pager)
      @page_jobs = page_jobs.map{|j| Job.new(j)}
      @pager = pager
    end
  end
end
