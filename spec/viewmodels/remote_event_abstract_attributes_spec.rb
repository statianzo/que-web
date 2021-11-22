require "spec_helper"

describe Que::Web::Viewmodels::RemoteEventAbstractAttributes do
  let(:scheme) { 'http' }
  let(:base_url) { 'hello.com' }
  let(:remote_event_data) {
    {
      id: '1',
      type: 'Chi::Remote::Transmitter',
      gateway: "#{scheme}://#{base_url}",
      data: { chi_event: { id: '2' } }
    }
  }
  let(:remote_event) { Que::Web::Viewmodels::RemoteEvent.new(remote_event_data) }
  let(:subject) { Que::Web::Viewmodels::RemoteEventAbstractAttributes.new(remote_event, { scheme: scheme, base_url: base_url }) }
  let(:event_id) { remote_event_data[:data][:chi_event][:id] }
  let(:external_remote_event_type) { 'Receiver' }
  let(:external_remote_event_url) do
    "#{remote_event_data[:gateway]}/chi/jobs/chi_remote_events/#{remote_event_data[:id]}"
  end
  let(:local_event_url) { "/chi/jobs/events/#{event_id}" }
  let(:external_event_url) { "#{remote_event_data[:gateway]}/chi/jobs/events/#{event_id}" }

  it 'computes correct external_remote_event_type' do
    _(subject.external_remote_event_type).must_equal(external_remote_event_type)
  end

  it 'computes correct external_remote_event_url' do
    _(subject.external_remote_event_url).must_equal(external_remote_event_url)
  end

  it 'computes correct local_event_url' do
    _(subject.local_event_url).must_equal(local_event_url)
  end

  it 'computes correct external_event_url' do
    _(subject.external_event_url).must_equal(external_event_url)
  end

  it 'computes correct event_id' do
    _(subject.event_id).must_equal(event_id)
  end
end
