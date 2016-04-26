require File.dirname(__FILE__)+'/ranked-model/ranker'
require File.dirname(__FILE__)+'/ranked-model/railtie' if defined?(Rails::Railtie)

module RankedModel

  # MAX_RANK_VALUE and MIN_RANK_VALUE are set to MySQL's 3-byte MEDIUMINT
  # range by default. However, as PostgreSQL doesn't have a 3-byte integer
  # data type and Postgres users are forced into allocating a 4-byte integer
  # anyway, we may as well use the full 4-byte range  to reduce the chance of
  # potentially expensive rebalancing.
  #
  # Signed 4-byte INTEGER in PostgreSQL: -2147483648 to +2147483647
  # Signed 3-byte MEDIUMINT in MySQL: -8388607 to +8388607
  #
  # SQLite3 allocates space according to size of each value, so we'll stick
  # with the defaults.
  MAX_RANK_VALUE = -> {
    case ActiveRecord::Base.connection.adapter_name.downcase.to_sym
    when :postgresql
      2147483647
    else
      8388607
    end
  }

  MIN_RANK_VALUE = -> {
    case ActiveRecord::Base.connection.adapter_name.downcase.to_sym
    when :postgresql
      -2147483648
    else
      -8388607
    end
  }

  def self.included base

    base.class_eval do
      class_attribute :rankers

      extend RankedModel::ClassMethods

      before_save :handle_ranking

      scope :rank, lambda { |name|
        order ranker(name.to_sym).column
      }
    end

  end

  private

  def handle_ranking
    self.class.rankers.each do |ranker|
      ranker.with(self).handle_ranking
    end
  end

  module ClassMethods

    def ranker name
      rankers.find do |ranker|
        ranker.name == name
      end
    end

  private

    def ranks *args
      self.rankers ||= []
      ranker = RankedModel::Ranker.new(*args)
      self.rankers << ranker
      attr_reader "#{ranker.name}_position"
      define_method "#{ranker.name}_position=" do |position|
        if position.present?
          send "#{ranker.column}_will_change!"
          instance_variable_set "@#{ranker.name}_position", position
        end
      end

      public "#{ranker.name}_position", "#{ranker.name}_position="
    end

  end

end
