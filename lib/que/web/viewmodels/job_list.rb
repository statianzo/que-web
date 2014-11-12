module Que::Web::Viewmodels
  class JobList
    PAGE_SIZE = 10

    attr_reader :page_jobs, :total, :page

    def initialize(page_jobs, total, page)
      @page_jobs = page_jobs.map{|j| Job.new(j)}
      @total = total
      @page = page
    end

    def next_page
      page.succ
    end

    def prev_page
      page.pred
    end

    def has_next?
      @page_jobs.length >= PAGE_SIZE
    end

    def has_prev?
      @page > 0
    end
  end
end
