require "spec_helper"

describe Que::Web::Viewmodels::Job do
  let(:source_job) {
    {priority: 100, run_at:  Time.now - 3600,
     job_id: 555, job_class: "SuccessJob",
     args: ["arg1", {name: "foo", age: 10}],
     error_count: 0,
     last_error_message: nil,
     last_error_backtracd: nil,
     queue: "foo"
    }
  }
  let(:subject) { Que::Web::Viewmodels::Job.new(source_job) }

  it 'maps fields from source' do
    _(subject.priority).must_equal source_job[:priority]
    _(subject.queue).must_equal source_job[:queue]
  end

  describe 'humanized_job_class' do
    it 'returns job class on unknown wrapper' do
      _(subject.humanized_job_class).must_equal "SuccessJob"
    end

    it 'returns wrapped job class for Active Job' do
      source = source_job.merge(job_class: "ActiveJob::QueueAdapters::QueAdapter::JobWrapper", args: [job_class: "MyJob"])
      job = Que::Web::Viewmodels::Job.new(source)
      _(job.humanized_job_class).must_equal "MyJob"
    end
  end

  describe 'schedule' do
    it 'is past due when run_at is behind' do
      _(subject).must_be :past_due?
    end

    it 'is not past due when run_at is ahead of now' do
      subject.run_at = Time.now + 3600
      _(subject).wont_be :past_due?
    end
  end
end
