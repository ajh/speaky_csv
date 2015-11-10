require 'spec_helper'

describe SpeakyCsv do
  let(:presenter_klass) do
    Class.new do
      include SpeakyCsv
    end
  end

  subject { presenter_klass.new }

  describe 'to_csv' do
    context 'with simple fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', 'author'
          end
        end
      end

      it 'should return csv' do
        book1 = double('book1', name: 'Big Fiction', author: 'Sneed')
        book2 = double('book2', name: 'True story', author: 'Honest Abe')

        csv = subject.to_csv [book1, book2]
        expect(csv).to eq <<-CSV
name,author
Big Fiction,Sneed
True story,Honest Abe
        CSV
      end
    end

    context 'with has_many fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', 'author'
            d.has_many 'reviews', %w(tomatoes publication)
          end
        end
      end

      it 'should return csv' do
        book1 = double 'book1',
                       name: 'Big Fiction',
                       author: 'Sneed',
                       reviews: [
                         double(tomatoes: 99, publication: 'Post'),
                         double(tomatoes: 15, publication: 'Daily')
                       ]

        book2 = double 'book2',
                       name: 'True story',
                       author: 'Honest Abe',
                       reviews: [
                         double(tomatoes: 50, publication: 'Daily')
                       ]

        csv = subject.to_csv [book1, book2]
        expect(csv).to eq <<-CSV
name,author,,,,,,,,
Big Fiction,Sneed,review_0_tomatoes,99,review_0_publication,Post,review_1_tomatoes,15,review_1_publication,Daily
True story,Honest Abe,review_0_tomatoes,50,review_0_publication,Daily
        CSV
      end
    end
  end

  describe 'from_csv' do
    context 'with simple fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', 'author'
          end
        end
      end

      it 'should return a data structure' do
        data = subject.from_csv <<-CSV
name,author
Big Fiction,Sneed
True story,Honest Abe
        CSV

        expect(data).to eq([
          { 'name' => 'Big Fiction', 'author' => 'Sneed' },
          { 'name' => 'True story', 'author' => 'Honest Abe' }
        ])
      end
    end

    context 'with has_many fields' do
      before do
        presenter_klass.class_eval do
          define_csv_fields do |d|
            d.field 'name', 'author'
            d.has_many 'reviews', %w(tomatoes publication)
          end
        end
      end

      it 'should return csv' do
        data = subject.from_csv <<-CSV
name,author,,,,,,,,
Big Fiction,Sneed,review_0_tomatoes,99,review_0_publication,Post,review_1_tomatoes,15,review_1_publication,Daily
True story,Honest Abe,review_0_tomatoes,50,review_0_publication,Daily
        CSV

        expect(data).to eq([
          {
            'name' => 'Big Fiction',
            'author' => 'Sneed',
            'reviews' => [
              { 'tomatoes' => '99', 'publication' => 'Post' },
              { 'tomatoes' => '15', 'publication' => 'Daily' }
            ]
          },
          {
            'name' => 'True story',
            'author' => 'Honest Abe',
            'reviews' => [
              { 'tomatoes' => '50', 'publication' => 'Daily' }
            ]
          }
        ])
      end
    end

    it "should fail when all headers aren't to the left"
    it 'should ignore undefined variable columns'
    it 'should fail when variable columns not pair up correctly'
  end
end
