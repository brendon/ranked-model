require File.dirname(__FILE__)+'/ranked-model/ranker'
require File.dirname(__FILE__)+'/ranked-model/railtie' if defined?(Rails::Railtie)

module RankedModel

  # Signed MEDIUMINT in MySQL
  #
  MAX_RANK_VALUE = 8388607
  MIN_RANK_VALUE = -8388607

  def self.included base

    base.class_eval do
      cattr_accessor :rankers

      extend RankedModel::ClassMethods

      before_save :handle_ranking

      scope :rank, lambda { |name|
        order arel_table[ ranker(name.to_sym).column ]
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
      attr_accessor "#{ranker.name}_position"
    end

  end

end
