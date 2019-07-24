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

    rails_version = ActiveRecord.version.to_s
    if rails_version < '5.0'
      base.module_eval <<-EOS, __FILE__, __LINE__ + 1
        def handle_ranking_return_value(return_value)
          @ranked_model_ranking_succeeded
        end

        def abort_handle_ranking
          nil
        end
      EOS
    end
  end

  private

  def handle_ranking
    @ranked_model_ranking_succeeded = true
    return_value = self.class.rankers.each do |ranker|
      ranking_failed_reason = catch :ranking_failed do
        ranker.with(self).handle_ranking
        nil
      end
      handle_ranking_failure(ranker, ranking_failed_reason)
    end
    handle_ranking_return_value(return_value)
  end

  def handle_ranking_failure(ranker, ranking_failed_reason)
    return if ranking_failed_reason.nil?
    errors.add ranker.column, ranking_failed_reason
    @ranked_model_ranking_succeeded = false
    abort_handle_ranking
  end

  # May be overriden
  def handle_ranking_return_value(return_value)
    return_value
  end

  # May be overriden
  def abort_handle_ranking
    throw :abort
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

      define_method "#{ranker.name}_rank" do
        ranker.with(self).relative_rank
      end

      public "#{ranker.name}_position", "#{ranker.name}_position="
    end

    def column_default ranker
      column_defaults[ranker.name.to_s] if ActiveRecord::Base.connected?
    end

  end

end
