require "spec_helper"
require "que/web"

describe Que::Web::Helpers do
  subject { Que::Web::Helpers.new(4, 10, 105) }

  def subject_with_attributes(**attributes)
    Class.new do
      include Que::Web::Helpers

      attributes.each { |attr, value| define_method(attr) { value } }
    end.new
  end

  describe '#search' do
    it 'returns a wildcard search with a search_param' do
      subject_with_attributes(search_param: 'foobar').search.must_equal '%foobar%'
    end

    it 'returns a wildcard search without a search_param' do
      subject_with_attributes(search_param: nil).search.must_equal '%'
    end
  end

  describe '#search_param' do
    def search_param_for(search)
      subject_with_attributes(params: { 'search' => search }).search_param
    end

    it 'is nil if the search_param is not present' do
      assert_nil(search_param_for(nil))
    end

    it 'is nil if the search_param is present but empty' do
      assert_nil(search_param_for(''))
    end

    it 'is nil if the search_param is empty after sanitisation' do
      assert_nil(search_param_for('! ?'))
    end

    it 'preserves a valid Ruby class name' do
      search_param_for("Namespaced::Class").must_equal 'Namespaced::Class'
    end

    it 'sanitises the passed search' do
      search_param_for("(Foo) / !Bar! --Baz").must_equal 'FooBarBaz'
    end

    it 'preserves A-Z, a-z, 0-9 and : in the search param' do
      search = (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).join + ':'
      search_param_for(search).must_equal search
    end
  end
end
