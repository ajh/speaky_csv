require 'spec_helper'
require 'stringio'

describe SpeakyCsv::Export do
  let(:presenter_klass) { Class.new SpeakyCsv::Base }

  let(:io) { StringIO.new }
  subject { presenter_klass.exporter records.each }

  def output
    subject.to_a.join
  end

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

  context 'with _destroy field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'id', 'name', '_destroy'
        end
      end
    end

    let(:records) do
      [
        double('book1', id: 4, name: 'Big Fiction', author: 'Sneed'),
        double('book2', id: 8, name: 'True story', author: 'Honest Abe')
      ]
    end

    it 'should write to io' do
      expect(output).to eq <<-CSV
id,name,_destroy
4,Big Fiction,
8,True story,
      CSV
    end

    it 'doesnt log that _destroy is an unknown field' do
      subject.to_a
      expect(subject.log).to_not match(/_destroy is not a method/)
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

  context 'with unknown field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :unknown
        end
      end
    end

    let(:records) { [double('book1')] }

    it 'adds an error to the log' do
      subject.to_a
      expect(subject.log).to match(/unknown is not a method/)
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

  context 'with unknown has_many field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id
          d.has_many :reviews do |r|
            r.field :unknown
          end
        end
      end
    end

    let(:records) { [double('book1', id: 22, reviews: [double(tomatoes: 99)])] }

    it 'adds an error' do
      subject.to_a
      expect(subject.log).to match(/reviews_unknown is not a method/)
    end
  end

  context 'with unknown has_many association' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id
          d.has_many :unknowns do |r|
            r.field :name
          end
        end
      end
    end

    let(:records) { [double('book1', id: 22, reviews: [double(tomatoes: 99)])] }

    it 'adds an error' do
      subject.to_a
      expect(subject.log).to match(/unknowns is not a method/)
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

    let(:records) do
      [
        double('book1',
               name: 'Big Fiction',
               author: 'Sneed',
               publisher: double(id: 99, name: 'Post')),
        double('book2',
               name: 'True story',
               author: 'Honest Abe',
               publisher: double(id: 50, name: 'Daily'))
      ]
    end
    it 'should return csv' do
      expect(output).to eq <<-CSV
name,author,publisher_id,publisher_name
Big Fiction,Sneed,99,Post
True story,Honest Abe,50,Daily
      CSV
    end
  end

  context 'with export_only has_one field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'id'
          d.has_one 'publisher' do |r|
            r.field :id
            r.field :name, export_only: true
          end
        end
      end
    end

    let(:records) do
      [
        double('book1',
               id: 22,
               publisher: double(id: 99, name: 'Post')),
      ]
    end

    it 'should write field' do
      expect(output).to eq <<-CSV
id,publisher_id,publisher_name
22,99,Post
      CSV
    end
  end

  context 'with unknown has_many field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'id'
          d.has_one 'publisher' do |r|
            r.field :unknown
          end
        end
      end
    end

    let(:records) do
      [
        double('book1',
               id: 22,
               publisher: double(id: 99, name: 'Post')),
      ]
    end

    it 'adds an error' do
      subject.to_a
      expect(subject.log).to match(/publisher_unknown is not a method/)
    end
  end

  context 'with unknown has_many association' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field 'id'
          d.has_one 'unknown' do |r|
            r.field :name
          end
        end
      end
    end

    let(:records) do
      [
        double('book1',
               id: 22,
               publisher: double(id: 99, name: 'Post')),
      ]
    end

    it 'adds an error' do
      subject.to_a
      expect(subject.log).to match(/unknown is not a method/)
    end
  end
end
