module Que::Web::Viewmodels
  class RemoteEventAbstractAttributes < Struct.new(
    :external_remote_event_type, :external_remote_event_url,
    :local_event_url, :external_event_url, :event_id
  )
    TRANSMITTER_TYPE = "Chi::Remote::Transmitter"

    def initialize(remote_event, request_base_url)
      @remote_event = remote_event
      @request_base_url = request_base_url

      self[:external_remote_event_type] = remote_event_is_transmitter? ? "Receiver" : "Transmitter"
      self[:external_remote_event_url] = generate_external_remote_event_url
      self[:local_event_url] = generate_local_event_url
      self[:external_event_url] = generate_external_event_url
      self[:event_id] = event_id_from_remote_data
    end

    private

    def generate_external_remote_event_url
      "#{remote_event_gateway_base_url}/chi/jobs/chi_remote_events/#{@remote_event.id}"
    end

    def generate_local_event_url
      "/chi/jobs/events/#{event_id_from_remote_data}"
    end

    def generate_external_event_url
      "#{remote_event_gateway_base_url}/chi/jobs/events/#{event_id_from_remote_data}"
    end

    # Transmitter gateways have viable url (eg. 'http://accounts-contracts-api.homestars.int'),
    # while receiver gateways are snake_case service name (eg. 'accounts_contracts_api')
    def remote_event_gateway_base_url
      if remote_event_is_transmitter?
        @remote_event.gateway
      else
        tld = @request_base_url.split('.').last
        "http://#{@remote_event.gateway.gsub('_', '-')}.homestars.#{tld}"
      end
    end

    def event_id_from_remote_data
      @remote_event.data[:chi_event][:id]
    end

    def remote_event_is_transmitter?
      @remote_event.type == TRANSMITTER_TYPE
    end
  end
end
