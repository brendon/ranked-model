require File.dirname(__FILE__)+'/ranked-model/ranker'
require File.dirname(__FILE__)+'/ranked-model/railtie' if defined?(Rails::Railtie)

module RankedModel

  class NonNilColumnDefault < StandardError; end

  # Signed INT in MySQL
  #
  MAX_RANK_VALUE = 2147483647
  MIN_RANK_VALUE = -2147483648

  def self.included base

    base.class_eval do
      class_attribute :rankers

      extend RankedModel::ClassMethods

      before_save :handle_ranking

      scope :rank, lambda { |name|
        reorder ranker(name.to_sym).column
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

      if column_default(ranker)
        raise NonNilColumnDefault, %Q{Your ranked model column "#{ranker.name}" must not have a default value in the database.}
      end

      self.rankers << ranker
      attr_reader "#{ranker.name}_position"
      define_method "#{ranker.name}_position=" do |position|
        if position.present?
          send "#{ranker.column}_will_change!"
          instance_variable_set "@#{ranker.name}_position", position
        end
      end

      after_save :"update_#{ranker.name}_position", if: :"inferred_#{ranker.name}_position?"

      define_method "#{ranker.name}_rank" do
        ranker.with(self).relative_rank
      end

      define_method "inferred_#{ranker.name}_position?" do
        send("#{ranker.column}_changed?") &&
          !send("#{ranker.name}_position").is_a?(Integer)
      end

      define_method "update_#{ranker.name}_position" do
        instance_variable_set "@#{ranker.name}_position", send("#{ranker.column}_rank")
      end

      public "#{ranker.name}_position", "#{ranker.name}_position="
    end

    def column_default ranker
      column_defaults[ranker.name.to_s] if ActiveRecord::Base.connected? && table_exists?
    end

  end

end
