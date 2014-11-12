require "spec_helper"

describe Que::Web::Viewmodels::JobList do
  let(:job) {
    {"priority"=>100, "run_at"=> Time.now,
     "job_id"=>555, "job_class"=>"SuccessJob",
     "args"=>["arg1", {"name"=>"foo", "age"=>10}],
     "error_count"=>0,
     "last_error"=>nil,
     "queue"=>"foo"
    }
  }
  let(:subject) { Que::Web::Viewmodels::JobList.new([job], 1, 3) }

  it "maps jobs" do
    subject.page_jobs.length.must_equal 1
    subject.page_jobs.first.queue.must_equal "foo"
  end

  it "provides next page" do
    subject.next_page.must_equal 4
  end

  it "provides prevous page" do
    subject.prev_page.must_equal 2
  end

  it "has next when full page" do
    subject.page_jobs.concat [job] * 9
    subject.has_next?.must_equal true
  end

  it "does not have next not full page" do
    subject.has_next?.must_equal false
  end

  it "has prev page when greater than 0" do
    subject.has_prev?.must_equal true
  end

  it "does not have prev page when equal to 0" do
    list = subject.class.new([], 1, 0) 
    list.has_prev?.must_equal false
  end

  it "does not have next not full page" do
    subject.has_next?.must_equal false
  end
end
