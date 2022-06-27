require "spec_helper"
require "pg_query"

describe Que::Web::SQL do
  it "has valid SQL" do
    Que::Web::SQL.keys.each do |key|
      begin
        PgQuery.parse(Que::Web::SQL[key])
      rescue
        raise "Invalid SQL detected in Que::Web::SQL for '#{key}'"
      end
    end
  end
end