module SpeakyCsv
  # An instance of this class is yielded to the block passed to
  # define_csv_fields. Used to configure speaky csv.
  class ConfigBuilder
    attr_reader :config

    def initialize(config: Config.new, root: true)
      @config = config
      @config.root = root
    end

    # Add one or many fields to the csv format.
    #
    # If options are passed, they apply to all given fields.
    def field(*fields, export_only: false)
      @config.fields += fields.map(&:to_sym)
      @config.fields.uniq!

      if export_only
        @config.export_only_fields += fields.map(&:to_sym)
        @config.export_only_fields.uniq!
      end

      nil
    end

    # Define a custom primary key. By default an `id` column as used.
    #
    # Accepts the same options as #field
    def primary_key=(name, options = {})
      field name, options
      @config.primary_key = name.to_sym
    end

    # Define a one to one association. This is also aliased as `belongs_to`. Expects a name and a block to
    # define the fields on associated record.
    #
    # For example:
    #
    #   define_csv_fields do |c|
    #     has_many 'publisher' do |p|
    #       p.field :id, :name, :_destroy
    #     end
    #   end
    #
    def has_one(name)
      @config.root or raise NotImplementedError, "nested associations are not supported"
      @config.has_ones[name.to_sym] ||= Config.new
      yield self.class.new config: @config.has_ones[name.to_sym], root: false

      nil
    end
    alias :belongs_to :has_one

    # Define a one to many association. Expect a name and a block to
    # define the fields on associated records.
    #
    # For example:
    #
    #   define_csv_fields do |c|
    #     has_many 'reviews' do |r|
    #       r.field :id, :name, :_destroy
    #     end
    #   end
    #
    def has_many(name)
      @config.root or raise NotImplementedError, "nested associations are not supported"
      @config.has_manys[name.to_sym] ||= Config.new
      yield self.class.new config: @config.has_manys[name.to_sym], root: false

      nil
    end
  end
end
