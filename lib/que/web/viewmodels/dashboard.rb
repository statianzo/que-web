module Que::Web::Viewmodels
  class Dashboard
    attr_reader :running, :scheduled, :failing
    def initialize(job_stats, failing_count)
      @running = calculate_running(job_stats)
      @scheduled = calculate_scheduled(job_stats)
      @failing = failing_count
    end


    private

    def calculate_running(job_stats)
      job_stats.map{|s| s["count_working"]}.reduce(0, :+)
    end

    def calculate_scheduled(job_stats)
      job_stats.map{|s| s["count"]}.reduce(0, :+)
    end
  end
end
