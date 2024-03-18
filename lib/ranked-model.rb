require File.dirname(__FILE__)+'/ranked-model/ranker'
require File.dirname(__FILE__)+'/ranked-model/advisory_lock'
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

      scope :rank, lambda { |name|
        reorder ranker(name.to_sym).column
      }
    end

  end

  private

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

      if ActiveRecord::Base.connected? && table_exists? && column_defaults[ranker.name.to_s]
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

      define_method "#{ranker.name}_rank" do
        ranker.with(self).relative_rank
      end

      public "#{ranker.name}_position", "#{ranker.name}_position="

      if ActiveRecord::Base.connected? && table_exists?
        advisory_lock = AdvisoryLock.new(base_class, ranker.column)
        before_create advisory_lock
        before_update advisory_lock
        before_destroy advisory_lock
      end

      before_save { ranker.with(self).handle_ranking }

      if ActiveRecord::Base.connected? && table_exists? && local_variables.include?(:advisory_lock)
        after_commit advisory_lock
        after_rollback advisory_lock
      end
    end

  end

end
