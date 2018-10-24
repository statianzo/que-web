require "spec_helper"

describe Que::Web::Viewmodels::Dashboard do
  let(:dashboard_stats) {
    {
      total: 10,
      running: 6,
      failing: 2,
      scheduled: 2
    }
  }
  let(:subject) { Que::Web::Viewmodels::Dashboard.new(dashboard_stats) }

  it 'passes through values' do
    subject.scheduled.must_equal 2
  end
end
