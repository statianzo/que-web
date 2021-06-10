json.set! :events do
  json.array!(@events_list.events)
end

json.set! :remote_events do
  json.array!(@remote_events_list.events)
end
