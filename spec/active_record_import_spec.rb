require 'spec_helper'
require 'support/active_record'

describe SpeakyCsv::ActiveRecordImport, :db do
  let(:presenter_klass) { Class.new SpeakyCsv::Base }

  let(:io) { StringIO.new }
  subject { presenter_klass.new.active_record_importer io, Book }

  def record
    unless defined? @record
      records = subject.to_a
      expect(records.length).to be <= 1
      @record = records.first
    end

    @record
  end

  context 'with fields' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id, :name, :author, :_destroy
        end
      end
    end

    context 'and csv has a new record' do
      let(:io) do
        StringIO.new <<-CSV
id,name,author
,Big Fiction,Sneed
        CSV
      end

      it 'returns new record' do
        expect(record.attributes).to include('name' => 'Big Fiction',
                                             'author' => 'Sneed')
        expect(record).to be_new_record
      end
    end

    context 'and csv has no changes' do
      let!(:book) { Book.create! id: 1, name: 'Big Fiction', author: 'Sneed' }

      let(:io) do
        StringIO.new <<-CSV
id,name,author
1,Big Fiction,Sneed
        CSV
      end

      it 'returns clean record' do
        expect(record.attributes).to include('id' => 1,
                                             'name' => 'Big Fiction',
                                             'author' => 'Sneed')
        expect(record).to_not be_changed
      end
    end

    context 'and csv has changes' do
      let!(:book) { Book.create! id: 1, name: 'Big Fiction', author: 'Sneed' }

      let(:io) do
        StringIO.new <<-CSV
id,name,author
1,Wee Little Fiction,Sneed
        CSV
      end

      it 'returns dirty record' do
        expect(record.name).to eq 'Wee Little Fiction'
        expect(record).to be_changed # not saved yet
      end
    end

    context 'and csv has a destroy' do
      let!(:book) { Book.create! id: 1, name: 'Big Fiction', author: 'Sneed' }

      let(:io) do
        StringIO.new <<-CSV
id,_destroy
1,true
        CSV
      end

      it 'returns record marked for destruction' do
        expect(record).to be_marked_for_destruction
      end
    end
  end

  context 'with has_many field' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id
          d.has_many 'reviews', %w(id tomatoes publication _destroy)
        end
      end
    end

    let!(:book) { Book.create! id: 1 }

    def actual_review
      unless defined? @review
        expect(record.reviews.length).to be <= 1
        @review = record.reviews.first
      end

      @review
    end

    context 'and csv has new associated record' do
      let(:io) do
        StringIO.new <<-CSV
id
1,review_0_tomatoes,99,review_0_publication,Post
        CSV
      end

      it 'builds new record' do
        expect(actual_review.attributes).to include('book_id' => 1,
                                                    'tomatoes' => 99,
                                                    'publication' => 'Post')
        expect(actual_review).to be_new_record
      end
    end

    context 'and csv has unchanged associated record' do
      let(:io) do
        StringIO.new <<-CSV
id
1,review_0_id,1,review_0_tomatoes,99,review_0_publication,Post
        CSV
      end

      let!(:review) { Review.create! id: 1, book: book, tomatoes: 99, publication: 'Post' }

      it 'returns clean record' do
        expect(actual_review).to_not be_changed
      end
    end

    context 'and csv changes associated record' do
      let(:io) do
        StringIO.new <<-CSV
id
1,review_0_id,1,review_0_tomatoes,80,review_0_publication,Post
        CSV
      end

      let!(:review) { Review.create! id: 1, book: book, tomatoes: 99, publication: 'Post' }

      it 'returns clean record' do
        expect(actual_review.tomatoes).to eq 80
        expect(actual_review).to be_changed
      end
    end
    context 'and csv destroys associated record' do
      let(:io) do
        StringIO.new <<-CSV
id
1,review_0_id,1,review_0__destroy,true
        CSV
      end

      let!(:review) { Review.create! id: 1, book: book, tomatoes: 99, publication: 'Post' }

      it 'marks record for destruction' do
        expect(actual_review).to be_marked_for_destruction
      end
    end
  end

  it "should fail when all headers aren't to the left"
  it 'should ignore undefined variable columns'
  it 'should fail when variable columns not pair up correctly'

  describe 'batch behavior' do
    before do
      presenter_klass.class_eval do
        define_csv_fields do |d|
          d.field :id, :name, :author, :_destroy
        end
      end
    end

    let!(:book1) { Book.create! id: 1, name: 'Big Fiction', author: 'Sneed' }
    let!(:book2) { Book.create! id: 2, name: 'Big NonFiction', author: 'Sneed' }
    let!(:book3) { Book.create! id: 3, name: 'The Last Goodbye', author: 'Sneed' }

    let(:io) do
      StringIO.new <<-CSV
id,name,author,_destroy
,Natty,Sneed
1,Big Fiction,Sneed
2,Wee Little NonFiction,Sneed
3,,,true
      CSV
    end

    def expect_changes_to_be_correct
      records = subject.to_a
      aggregate_failures 'changes' do
        expect(records.length).to eq 4
        new_one = records.find(&:new_record?)
        expect(new_one.attributes).to include('name' => 'Natty',
                                              'author' => 'Sneed')
        book1 = records.find { |b| b.id == 1 }
        expect(book1).to_not be_changed

        book2 = records.find { |b| b.id == 2 }
        expect(book2.attributes).to include('name' => 'Wee Little NonFiction',
                                            'author' => 'Sneed')
        expect(book2).to be_changed

        book3 = records.find { |b| b.id == 3 }
        expect(book3).to be_marked_for_destruction
      end
    end

    context 'when batch size is less than csv size' do
      before do
        stub_const 'SpeakyCsv::ActiveRecordImport::QUERY_BATCH_SIZE', 2
      end

      it 'works' do
        expect_changes_to_be_correct
      end
    end

    context 'when batch size is same as csv size' do
      before do
        stub_const 'SpeakyCsv::ActiveRecordImport::QUERY_BATCH_SIZE', 4
      end

      it 'works' do
        expect_changes_to_be_correct
      end
    end

    context 'when batch size is greater than as csv size' do
      before do
        stub_const 'SpeakyCsv::ActiveRecordImport::QUERY_BATCH_SIZE', 6
      end

      it 'works' do
        expect_changes_to_be_correct
      end
    end
  end
end
