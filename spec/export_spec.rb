require 'spec_helper'
require 'stringio'

describe SpeakyCsv::Export do
  let(:presenter_klass) { Class.new SpeakyCsv::Base }

  let(:io) { StringIO.new }
  subject { presenter_klass.new.exporter records.each }

  def output
    subject.to_a.join
  end

  describe 'call' do
    context 'with fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', 'author'
          end
        end
      end

      let(:records) do
        [
          double('book1', name: 'Big Fiction', author: 'Sneed'),
          double('book2', name: 'True story', author: 'Honest Abe')
        ]
      end

      it 'should write to io' do
        expect(output).to eq <<-CSV
name,author
Big Fiction,Sneed
True story,Honest Abe
        CSV
      end
    end

    context 'with export_only fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', export_only: true
          end
        end
      end

      let(:records) { [double('book1', name: 'Big Fiction')] }

      it 'should write field' do
        expect(output).to eq <<-CSV
name
Big Fiction
        CSV
      end
    end

    context 'with has_many fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', 'author'
            d.has_many 'reviews' do |r|
              r.field :tomatoes, :publication
            end
          end
        end
      end

      let(:records) do
        [
          double('book1',
                 name: 'Big Fiction',
                 author: 'Sneed',
                 reviews: [
                   double(tomatoes: 99, publication: 'Post'),
                   double(tomatoes: 15, publication: 'Daily')
                 ]),
          double('book2',
                 name: 'True story',
                 author: 'Honest Abe',
                 reviews: [
                   double(tomatoes: 50, publication: 'Daily')
                 ])
        ]
      end
      it 'should return csv' do
        expect(output).to eq <<-CSV
name,author
Big Fiction,Sneed,review_0_tomatoes,99,review_0_publication,Post,review_1_tomatoes,15,review_1_publication,Daily
True story,Honest Abe,review_0_tomatoes,50,review_0_publication,Daily
        CSV
      end
    end

    context 'with export_only has_many field' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field :id
            d.has_many 'reviews' do |r|
              r.field :tomatoes, export_only: true
            end
          end
        end
      end

      let(:records) { [double('book1', id: 22, reviews: [double(tomatoes: 99)])] }

      it 'should write field' do
        expect(output).to eq <<-CSV
id
22,review_0_tomatoes,99
        CSV
      end
    end
  end
end
