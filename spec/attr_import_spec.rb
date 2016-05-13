require 'spec_helper'

describe SpeakyCsv::AttrImport do
  let(:presenter_klass) { Class.new SpeakyCsv::Base }

  let(:io) { StringIO.new }
  subject { presenter_klass.attr_importer io }

  context 'with fields' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name', 'author'
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
name,author
Big Fiction,Sneed
True story,Honest Abe
      CSV
    end

    it 'should return a data structure' do
      expect(subject.to_a).to eq([
        { 'name' => 'Big Fiction', 'author' => 'Sneed' },
        { 'name' => 'True story', 'author' => 'Honest Abe' }
      ])
    end

    context "when csv cell is empty" do
      let(:io) do
        StringIO.new <<-CSV
name,author
,Sneed
True story,
        CSV
      end

      it 'should return nil values' do
        expect(subject.to_a).to eq([
          { 'name' => nil, 'author' => 'Sneed' },
          { 'name' => 'True story', 'author' => nil }
        ])
      end
    end

    context "when a column isn't present" do
      let(:io) do
        StringIO.new <<-CSV
name
Big Fiction
True story
        CSV
      end

      it 'should not include that field in output' do
        expect(subject.to_a).to eq([
          { 'name' => 'Big Fiction' },
          { 'name' => 'True story' }
        ])
      end
    end
  end

  context 'with export_only field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id
          d.field :name, export_only: true
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
id,name
22,Big Fiction
      CSV
    end

    it 'should exclude field' do
      expect(subject.to_a).to eq([{ 'id' => '22' }])
    end

    it 'should log it' do
      subject.to_a
      expect(subject.log).to match(/name/)
    end
  end

  context 'with unknown columns' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name'
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
name,setting
Big Fiction,Chicago
True story,NYC
      CSV
    end

    it 'should ignores it' do
      expect(subject.to_a).to eq([
        { 'name' => 'Big Fiction' },
        { 'name' => 'True story' }
      ])
    end

    it 'should log it' do
      subject.to_a
      expect(subject.log).to match(/setting/)
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

    let(:io) do
      StringIO.new <<-CSV
name,author,,,,,,,,
Big Fiction,Sneed,review_0_tomatoes,99,review_0_publication,Post,review_1_tomatoes,15,review_1_publication,Daily
True story,Honest Abe,review_0_tomatoes,50,review_0_publication,Daily
      CSV
    end

    it 'should return attrs' do
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

    context 'when csv cell is empty' do
      let(:io) do
        StringIO.new <<-CSV
name,author,,,,,,,,
Big Fiction,Sneed,review_0_tomatoes,,review_0_publication,,review_1_tomatoes,,review_1_publication
True story,Honest Abe,review_0_tomatoes,,review_0_publication,,
        CSV
      end

      it 'should return nil values' do
        expect(subject.to_a).to eq([
          {
            'name' => 'Big Fiction',
            'author' => 'Sneed',
            'reviews' => [
              { 'tomatoes' => nil, 'publication' => nil },
              { 'tomatoes' => nil, 'publication' => nil }
            ]
          },
          {
            'name' => 'True story',
            'author' => 'Honest Abe',
            'reviews' => [
              { 'tomatoes' => nil, 'publication' => nil }
            ]
          }
        ])
      end
    end
  end

  context 'with has_one fields' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name', 'author'
          d.has_one 'publisher' do |r|
            r.field :id, :name
          end
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
name,author,publisher_id,publisher_name,
Big Fiction,Sneed,3,Dan Blam
True story,Honest Abe,50,Burt Bacharach
      CSV
    end

    it 'should return attrs' do
      expect(subject.to_a).to eq([
        {
          'name' => 'Big Fiction',
          'author' => 'Sneed',
          'publisher' => {
            'id' => '3', 'name' => 'Dan Blam'
          },
        },
        {
          'name' => 'True story',
          'author' => 'Honest Abe',
          'publisher' => {
            'id' => '50', 'name' => 'Burt Bacharach'
          }
        }
      ])
    end

    context 'when csv cell is empty' do
      let(:io) do
        StringIO.new <<-CSV
name,author,publisher_id,publisher_name,
Big Fiction,Sneed,,Dan Blam
True story,Honest Abe,50,
        CSV
      end

      it 'should return nil values' do
        expect(subject.to_a).to eq([
          {
            'name' => 'Big Fiction',
            'author' => 'Sneed',
            'publisher' => {
              'id' => nil, 'name' => 'Dan Blam'
            },
          },
          {
            'name' => 'True story',
            'author' => 'Honest Abe',
            'publisher' => {
              'id' => '50', 'name' => nil
            }
          }
        ])
      end
    end

    context "when a column isn't present" do
      let(:io) do
        StringIO.new <<-CSV
name,author,publisher_id
Big Fiction,Sneed,3
True story,Honest Abe,50
        CSV
      end

      it 'should not include that field in output' do
        expect(subject.to_a).to eq([
          {
            'name' => 'Big Fiction',
            'author' => 'Sneed',
            'publisher' => { 'id' => '3' },
          },
          {
            'name' => 'True story',
            'author' => 'Honest Abe',
            'publisher' => { 'id' => '50' }
          }
        ])
      end
    end
  end

  context 'with export_only has_many field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id
          d.has_many :reviews do |r|
            r.field :tomatoes, export_only: true
          end
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
id
22,reviews_0_tomatoes,99
      CSV
    end

    it 'should exclude field' do
      expect(subject.to_a).to eq([{ 'id' => '22' }])
    end
  end

  context 'with unknown has_many' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name'
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
name
Big Fiction,sales_0_count,99,sales_0_period,Q1
      CSV
    end

    it 'should ignore it' do
      expect(subject.to_a).to eq([{ 'name' => 'Big Fiction' }])
    end
  end

  context 'with unknown has_many field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name'
          d.has_many 'reviews' do |r|
            r.field :tomatoes
          end
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
name
Big Fiction,review_0_tomatoes,99,review_0_auther,Meanie
      CSV
    end

    it 'should ignore it' do
      expect(subject.to_a).to eq [{ 'name' => 'Big Fiction', 'reviews' => [{ 'tomatoes' => '99' }] }]
    end
  end

  context 'when csv is invalid' do
    before do
      allow(CSV).to receive(:new).and_raise(CSV::MalformedCSVError)
    end

    it 'adds an error' do
      expect(subject.to_a).to eq []
      expect(subject.log).to match(/csv is malformed/)
    end
  end

  context 'with weird rows' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'name', 'author'
        end
      end
    end

    let(:io) do
      StringIO.new <<-CSV
foo,bar,bax
1,2,3,2,1
,,

hihihi
      CSV
    end

    it 'always returns a hash per row' do
      expect(subject.to_a.length).to eq 4
    end
  end

  it 'should fail when variable columns not pair up correctly'
end
