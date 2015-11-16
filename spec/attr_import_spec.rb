require 'spec_helper'

describe SpeakyCsv::AttrImport do
  let(:presenter_klass) { Class.new SpeakyCsv::Base }

  let(:io) { StringIO.new }
  subject { presenter_klass.new.attr_importer io }

  context 'with simple fields' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name', 'author'
        end
      end
    end

    before do
      io.write <<-CSV
name,author
Big Fiction,Sneed
True story,Honest Abe
      CSV
      io.rewind
    end

    it 'should return a data structure' do
      expect(subject.to_a).to eq([
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

    before do
      io.write <<-CSV
name,author,,,,,,,,
Big Fiction,Sneed,review_0_tomatoes,99,review_0_publication,Post,review_1_tomatoes,15,review_1_publication,Daily
True story,Honest Abe,review_0_tomatoes,50,review_0_publication,Daily
      CSV
      io.rewind
    end

    it 'should return csv' do
      expect(subject.to_a).to eq([
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
