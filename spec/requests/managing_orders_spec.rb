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

  it 'adds line items' do

  end

  it 'removes line item' do

  end

  it 'places order' do

  end

  it 'completes order' do

  end
end
