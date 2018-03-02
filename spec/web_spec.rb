require 'spec_helper'

describe Que::Web::Helpers do
  subject do
    Class.new { include Que::Web::Helpers }.new
  end

  def error_job(last_error)
    Que::Web::Viewmodels::Job.new('last_error' => last_error)
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
end
