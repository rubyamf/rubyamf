require 'spec_helper.rb'
require 'active_support/time_with_zone'

describe "Rails integration" do
  it "should serialize TimeWithZone properly" do
    zone = ActiveSupport::TimeZone.new('America/New_York')
    time = Time.utc(2003, 2, 13, 0)
    time_with_zone = ActiveSupport::TimeWithZone.new(time.getutc, zone)
    RocketAMF.serialize(time_with_zone, 3).should == RocketAMF.serialize(time, 3)
  end

  describe "Rails 3", :if => Rails::VERSION::MAJOR == 3 do
    it "should convert ActiveRecord::Relation to array for serialization" do
      rel = Parent.where(:name => 'a')
      rel.should be_a ActiveRecord::Relation

      ser = RocketAMF.serialize(rel, 3)
      des = RocketAMF.deserialize(ser, 3)
      des.should be_a(Array)
    end
  end
end