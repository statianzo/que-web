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
      _(subject.format_error(
        error_job(last_error)
      )).must_equal 'This is a really long exception...'
    end

    it 'handles empty strings as the last error' do
      _(subject.format_error(error_job(''))).must_equal ''
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
        _(subject.search_running(jobs)).must_equal(jobs)
      end
    end

    describe 'when the search param is blank' do
      let(:search) { '' }

      it 'returns all the jobs' do
        _(subject.search_running(jobs)).must_equal(jobs)
      end
    end

    describe 'when the search param is present' do
      let(:search) { 'A' }

      it 'returns only the jobs whose class matches the search' do
        _(subject.search_running(jobs)).must_equal(
          [
            { job_class: 'JobClassA' },
            { job_class: 'JobClassA2' }
          ]
        )
      end
    end
  end

  describe '#relative_time' do
    it 'renders a Time object as a <time> HTML element' do
      time = Time.now
      _(subject.relative_time(time)).must_equal(
        %Q(<time class="timeago" datetime="#{time.utc.iso8601}">#{time.utc}</time>)
      )
    end

    it 'renders a String object without timezone in the format "YYYY-MM-DD HH:MM:SS" (e.g. "2020-09-06 22:17:03") as a <time> HTML element' do
      time = '2020-09-06 22:17:03'
      _(subject.relative_time(time)).must_equal(
        %Q(<time class="timeago" datetime="2020-09-06T22:17:03Z">2020-09-06 22:17:03 UTC</time>)
      )
    end
  end
end
