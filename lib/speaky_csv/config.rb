module SpeakyCsv
  # An instance of this class is yielded to the block passed to
  # define_csv_fields. Used to configure speaky csv.
  class Config
    attr_accessor \
      :export_only_fields,
      :fields,
      :has_manys,
      :has_ones,
      :primary_key,
      :root

    def initialize(root: true)
      @root = root
      @export_only_fields = []
      @fields = []
      @has_manys = {}
      @has_ones = {}
      @primary_key = :id
    end

    def dup
      other = super
      other.instance_variable_set '@has_manys', @has_manys.deep_dup
      other.instance_variable_set '@has_ones', @has_ones.deep_dup

      other
    end
  end
end
