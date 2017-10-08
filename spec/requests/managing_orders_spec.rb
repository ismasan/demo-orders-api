require 'spec_helper'

RSpec.describe 'managing orders', type: [:request] do
  let(:pusher) { instance_double(Pusher::Client, trigger: true) }
  before do
    allow(Pusher::Client).to receive(:new).and_return pusher
  end

  it 'creates orders' do
    o1 = root.create_order
    o2 = root.create_order

    expect(o1.id).not_to be_nil
    expect(o1.status).to eq 'open'

    expect(root.orders.total_items).to eq 2
    expect(root.orders.map(&:id).sort).to eq [o2.id, o1.id].sort
  end

  it 'gets a single order by id' do
    order = root.create_order

    order2 = root.order(id: order.id)

    expect(order.id).to eq order2.id
  end

  it 'adds items to orders' do
    order = root.create_order
    order = order.add_line_item(name: 'iPhone 8', price: 100, units: 2)
    order = order.add_line_item(name: 'Samsung Galaxy', price: 50, units: 1)

    expect(order.line_items.size).to eq 2
    expect(order.total).to eq 250
  end

  it 'removes line item' do

  end

  it 'places order' do

  end

  it 'completes order' do

  end
end
