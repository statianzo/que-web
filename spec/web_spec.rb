require 'spec_helper'

describe Que::Web::Helpers do
  let(:search) { '' }
  let(:params) { { 'search' => search } }

  subject do
    # Capture the params into an ivar so the params method block below captures it
    params_to_use = params

    Class.new do
      include Que::Web::Helpers

      define_method(:params) { params_to_use }
    end.new
  end

  def error_job(last_error)
    Que::Web::Viewmodels::Job.new(last_error_message: last_error)
  end

  describe '#format_error' do
    it 'returns the truncated first line of the last error' do
      message = 'This is a really long exception message that should get truncated'
      last_error = ([message] + caller).join("\n")
      subject.format_error(
        error_job(last_error)
      ).must_equal 'This is a really long exception...'
    end

    it 'handles empty strings as the last error' do
      subject.format_error(error_job('')).must_equal ''
    end
  end

  describe '#search_running' do
    let(:jobs) do
      [
        { job_class: 'JobClassA' },
        { job_class: 'JobClassB' },
        { job_class: 'JobClassA2' },
        { job_class: 'JobClassC' }
      ]
    end

    describe 'when the search param is not supplied' do
      let(:params) { {} }

      it 'returns all the jobs' do
        subject.search_running(jobs).must_equal(jobs)
      end
    end

    describe 'when the search param is blank' do
      let(:search) { '' }

      it 'returns all the jobs' do
        subject.search_running(jobs).must_equal(jobs)
      end
    end

    describe 'when the search param is present' do
      let(:search) { 'A' }

      it 'returns only the jobs whose class matches the search' do
        subject.search_running(jobs).must_equal(
          [
            { job_class: 'JobClassA' },
            { job_class: 'JobClassA2' }
          ]
        )
      end
    end
  end
end
