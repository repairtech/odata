require 'spec_helper'

describe OData::Service do
  let(:subject) { OData::Service.open('http://services.odata.org/OData/OData.svc') }
  let(:entity_types) { %w{Product FeaturedProduct ProductDetail Category Supplier Person Customer Employee PersonDetail Advertisement} }
  let(:complex_types) { %w{Address} }

  # We're calling this as a private method because there should not be any
  # reasons to have to flush the service registry except in testing.
  after :each do
    OData::ServiceRegistry.instance.send(:flush)
  end

  describe '.open' do
    it { expect(OData::Service).to respond_to(:open) }
  end

  it 'adds itself to OData::ServiceRegistry on creation' do
    expect(OData::ServiceRegistry['ODataDemo']).to be_nil
    expect(OData::ServiceRegistry['http://services.odata.org/OData/OData.svc']).to be_nil

    service = OData::Service.open('http://services.odata.org/OData/OData.svc')

    expect(OData::ServiceRegistry['ODataDemo']).to eq(service)
    expect(OData::ServiceRegistry['http://services.odata.org/OData/OData.svc']).to eq(service)
  end

  describe 'instance methods' do
    it { expect(subject).to respond_to(:service_url) }
    it { expect(subject).to respond_to(:entities) }
    it { expect(subject).to respond_to(:complex_types) }
    it { expect(subject).to respond_to(:namespace) }
  end

  describe '#service_url' do
    it { expect(subject.service_url).to eq('http://services.odata.org/OData/OData.svc') }
  end

  describe '#entities' do
    it { expect(subject.entities.size).to eq(10) }
    it { expect(subject.entities).to eq(entity_types) }
  end

  describe '#complex_types' do
    it { expect(subject.complex_types.size).to eq(1) }
    it { expect(subject.complex_types).to eq(complex_types) }
  end

  describe '#namespace' do
    it { expect(subject.namespace).to eq('ODataDemo') }
  end

  describe '#get' do
    it { expect(subject.get(::Examples::Product).size).to eq(11) }
    it { expect(subject.get(::Examples::Product, {key: 0}).size).to eq(1) }
  end
end