require 'spec_helper'

describe SpeakyCsv::Base do
  describe 'define_csv_fields' do
    let(:parent_klass) { Class.new SpeakyCsv::Base }
    let(:child_klass) { Class.new parent_klass }

    context 'when parent class has config' do
      before do
        parent_klass.class_eval do
          define_csv_fields do |d|
            d.field :name
            d.has_many :reviews do |r|
              r.field :tomatoes
            end
            d.has_one :publisher do |p|
              p.field :id
            end
          end
        end
      end

      it 'inherits it for child' do
        expect(child_klass.speaky_csv_config.fields).to eq [:name]
        expect(child_klass.speaky_csv_config.has_manys.keys).to eq [:reviews]
        expect(child_klass.speaky_csv_config.has_manys[:reviews].fields).to eq [:tomatoes]
        expect(child_klass.speaky_csv_config.has_ones[:publisher].fields).to eq [:id]
      end

      context 'and child adds to it' do
        before do
          child_klass.class_eval do
            define_csv_fields do |d|
              d.field :author
              d.has_many :sales do |s|
                s.field :period
              end
              d.has_many :reviews do |r|
                r.field :publication
              end
              d.has_one :publisher do |p|
                p.field :name
              end
            end
          end
        end

        it 'adds it to child' do
          expect(child_klass.speaky_csv_config.fields).to eq [:name, :author]
          expect(child_klass.speaky_csv_config.has_manys.keys.sort).to eq [:reviews, :sales].sort
          expect(child_klass.speaky_csv_config.has_manys[:reviews].fields).to eq [:tomatoes, :publication]
          expect(child_klass.speaky_csv_config.has_manys[:sales].fields).to eq [:period]
          expect(child_klass.speaky_csv_config.has_ones[:publisher].fields).to eq [:id, :name]
        end

        it 'doesnt change parents config' do
          expect(parent_klass.speaky_csv_config.fields).to_not include :author
          expect(parent_klass.speaky_csv_config.has_manys.keys).to_not include :sales
          expect(parent_klass.speaky_csv_config.has_manys[:reviews].fields).to_not include :publication
          expect(parent_klass.speaky_csv_config.has_ones[:publisher].fields).to_not include :name
        end
      end
    end

    it 'raises if association nesting is attempted' do
      expect do
        parent_klass.class_eval do
          define_csv_fields do |d|
            d.has_one :foo do |f|
              f.has_many :bars do |b|
                b.field 'name'
              end
            end
          end
        end
      end.to raise_error(NotImplementedError)
    end
  end
end
