require "spec_helper"

describe Que::Web::Viewmodels::Dashboard do
  let(:dashboard_stats) {
    {
      running: 6,
      queued: 2,
      scheduled: 3,
      failing: 4,
      errored: 5,
      failed: 6
    }
  }
  let(:subject) { Que::Web::Viewmodels::Dashboard.new(dashboard_stats) }

  it 'passes through running' do
    _(subject.running).must_equal 6
  end

  it 'passes through queued' do
    _(subject.queued).must_equal 2
  end

  it 'passes through scheduled' do
    _(subject.scheduled).must_equal 3
  end

  it 'passes through failing' do
    _(subject.failing).must_equal 4
  end

  it 'passes through errored' do
    _(subject.errored).must_equal 5
  end

  it 'passes through failed' do
    _(subject.failed).must_equal 6
  end
end
