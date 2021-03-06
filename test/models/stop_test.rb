require 'test_helper'

class StopTest < ActiveSupport::TestCase
  set_fixture_class :delayed_jobs => Delayed::Backend::ActiveRecord::Job

  test "should not save" do
    o = Stop.new
    assert_not o.save, "Saved without required fields"
  end

  test "get order" do
    o = routes(:route_one)
    o.planning.customer.enable_orders = true
    assert_not o.stops[0].order
    assert_not o.stops[1].order

    o.planning.apply_orders(order_arrays(:order_array_one), 0)
    o.planning.save!

    assert_equal [products(:product_one), products(:product_two)], o.stops[0].order.products.to_a
    assert o.stops[1].order.products.empty?
  end
end
