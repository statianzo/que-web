require "spec_helper"
require "que/web/pager"

describe Que::Web::Pager do
  subject { Que::Web::Pager.new(4, 10, 105) }

  it "provides passed values" do
    subject.current_page.must_equal 4
    subject.page_size.must_equal 10
    subject.total.must_equal 105
  end

  it "provides a page count" do
    subject.page_count.must_equal 11
  end

  it "defaults to page count of 1 if total is 0" do
    pager = Que::Web::Pager.new(4, 10, 0)
    pager.page_count.must_equal 1
  end

  it "increments next page if it exists" do
    subject.next_page.must_equal 5
  end

  it "provides nil next page if on last page" do
    pager = Que::Web::Pager.new(11, 10, 105)
    pager.next_page.must_be_nil
  end

  it "decrements prev page if it exists" do
    subject.prev_page.must_equal 3
  end

  it "provides nil prev page if on first page" do
    pager = Que::Web::Pager.new(1, 10, 105)
    pager.prev_page.must_be_nil
  end

  it "determines offset" do
    subject.offset.must_equal 30
  end

  it "sets page_no less than 1 to 1 for current page" do
    pager = Que::Web::Pager.new(-3, 10, 105)
    pager.current_page.must_equal 1
  end

  it "provides range centering current page" do
    pager = Que::Web::Pager.new(-3, 10, 105)
    pager.current_page.must_equal 1
  end
end
