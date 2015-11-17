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
          end
        end
      end

      it 'inherits it for child' do
        expect(child_klass.csv_field_builder.fields).to eq [:name]
        expect(child_klass.csv_field_builder.has_manys.keys).to eq [:reviews]
        expect(child_klass.csv_field_builder.has_manys[:reviews].fields).to eq [:tomatoes]
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
            end
          end
        end

        it 'adds it to child' do
          expect(child_klass.csv_field_builder.fields).to eq [:name, :author]
          expect(child_klass.csv_field_builder.has_manys.keys.sort).to eq [:reviews, :sales].sort
          expect(child_klass.csv_field_builder.has_manys[:reviews].fields).to eq [:tomatoes, :publication]
          expect(child_klass.csv_field_builder.has_manys[:sales].fields).to eq [:period]
        end

        it 'doesnt change parents config' do
          expect(parent_klass.csv_field_builder.fields).to_not include :author
          expect(parent_klass.csv_field_builder.has_manys.keys).to_not include :sales
          expect(parent_klass.csv_field_builder.has_manys[:reviews].fields).to_not include :publication
        end
      end
    end
  end
end
