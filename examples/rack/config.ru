require File.expand_path('../boot', __FILE__)
require 'que/web'

map '/que' do
  run Que::Web
end

map '/success' do
  run lambda { |env|
    SuccessJob.enqueue 'arg1', {name: 'foo', age: 10}
    [200, {}, ['Success job enqueued']]
  }
end

map '/fail' do
  run lambda { |env|
    FailJob.enqueue 'arg1', {name: 'fail', age: 20}
    [200, {}, ['Failing job queued']]
  }
end

map '/delay' do
  run lambda { |env|
    SuccessJob.enqueue 'arg1', {name: 'delay', age: 30}, run_at: Time.now + 300
    [200, {}, ['Delayed job queued']]
  }
end

map '/slow' do
  run lambda { |env|
    SlowJob.enqueue 'arg1', {name: 'delay', age: 30}
    [200, {}, ['Slow job queued']]
  }
end


map '/delayslow' do
  run lambda { |env|
    SlowJob.enqueue 'arg1', {name: 'delayslow', age: 20}, run_at: Time.now + 10
    [200, {}, ['Failing job queued']]
  }
end

run lambda { |env|
  [200, {}, ['Hello']]
}

