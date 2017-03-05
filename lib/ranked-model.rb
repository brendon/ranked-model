require File.dirname(__FILE__)+'/ranked-model/ranker'
require File.dirname(__FILE__)+'/ranked-model/railtie' if defined?(Rails::Railtie)

module RankedModel

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

      singleton_class.instance_eval do
        define_method "with_#{ranker.name}_position" do |with_same: nil|
          if with_same
            instances = self.all.to_a
            key_from_instance = case with_same
              when Symbol
                raise RankedModel::InvalidField, %Q{No field called "#{with_same}" found in model} unless self.public_instance_methods.include? with_same
                Proc.new do |t|
                  t.send(with_same)
                end
              when Array
                raise RankedModel::InvalidField, %Q{No field called "#{with_same}" found in model} unless (with_same - self.public_instance_methods).empty?
                Proc.new do |t|
                  with_same.map { |c| t.send(c) }
                end
              else
                raise RankedModel::InvalidField, %Q{No field called "#{with_same}" found in model}
            end
            indexes = {}

            instances.map do |instance|
              key = key_from_instance.call instance
              indexes[key] ||= 0
              instance.send("#{ranker.name}_position=", indexes[key])
              indexes[key] += 1
              instance
            end
          else
            self.all.map.with_index do |instance, index|
              instance.send("#{ranker.name}_position=", index)
              instance
            end
          end
        end

        public "with_#{ranker.name}_position"
      end
    end

  end

end
