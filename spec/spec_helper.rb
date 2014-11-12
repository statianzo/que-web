require "bundler/setup"
require "que/web"
require "minitest/autorun"

class CustomFilter
  def self.filter(bt)
    return ['No backtrace'] unless bt

    new_bt = bt.take_while { |line| line !~ %r{minitest} }
    new_bt = bt.select     { |line| line !~ %r{minitest} } if new_bt.empty?
    new_bt = bt.dup if new_bt.empty?

    new_bt
  end
end

Minitest.backtrace_filter = CustomFilter
