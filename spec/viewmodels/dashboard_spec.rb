require "spec_helper"

describe Que::Web::Viewmodels::Dashboard do
  let(:job_stats) {
    [
      {"queue"=>"", "job_class"=>"FailJob", "count"=>8, "count_working"=>0, "count_errored"=>8, "highest_error_count"=>11, "oldest_run_at"=> Time.new(2014,11,12,6,0,0)},
      {"queue"=>"", "job_class"=>"SuccessJob", "count"=>2, "count_working"=>2, "count_errored"=>2, "highest_error_count"=>0, "oldest_run_at"=> Time.new(2014,11,12,8,0,0)},
      {"queue"=>"", "job_class"=>"OtherJob", "count"=>7, "count_working"=>4, "count_errored"=>2, "highest_error_count"=>0, "oldest_run_at"=> Time.new(2014,11,12,9,0,0)}
    ]
  }
  let(:failing_count) { 7 }
  let(:subject) { Que::Web::Viewmodels::Dashboard.new(job_stats, failing_count) }

  it 'tallies running jobs' do
    subject.running.must_equal 6
  end

  it 'tallies scheduled jobs' do
    subject.scheduled.must_equal 17
  end

  it 'uses failing jobs' do
    subject.failing.must_equal failing_count
  end
end
