module RankedModel

  class InvalidScope < StandardError; end
  class InvalidField < StandardError; end

  class Ranker
    attr_accessor :name, :column, :scope, :with_same

    def initialize name, options={}
      self.name = name.to_sym
      self.column = options[:column] || name

      [ :scope, :with_same ].each do |key|
        self.send "#{key}=", options[key]
      end
    end

    def with instance
      Mapper.new self, instance
    end

    class Mapper
      attr_accessor :ranker, :instance

      def initialize ranker, instance
        self.ranker   = ranker
        self.instance = instance

        validate_ranker_for_instance!
      end
      
      def validate_ranker_for_instance!
        if ranker.scope && !instance.class.respond_to?(ranker.scope)
          raise RankedModel::InvalidScope, %Q{No scope called "#{ranker.scope}" found in model}
        end

        if ranker.with_same && !instance.respond_to?(ranker.with_same)
          raise RankedModel::InvalidField, %Q{No field called "#{ranker.with_same}" found in model}
        end
      end

      def handle_ranking
        update_index_from_position
        assure_unique_position
      end

      def update_rank! value
        # Bypass callbacks
        #
        instance.class.where(:id => instance.id).update_all ["#{ranker.column} = ?", value]
      end

      def position
        instance.send "#{ranker.name}_position"
      end

      def rank
        instance.send "#{ranker.column}"
      end

    private

      def position_at value
        instance.send "#{ranker.name}_position=", value
        update_index_from_position
      end

      def rank_at value
        instance.send "#{ranker.column}=", value
      end

      def rank_changed?
        instance.send "#{ranker.column}_changed?"
      end

      def new_record?
        instance.new_record?
      end

      def update_index_from_position
        case position
          when :first
            if !current_order.empty? && current_order.first.rank
              rank_at( current_order.first.rank / 2 )
            else
              rank_at 0
            end
          when :last
            if !current_order.empty? && current_order.last.rank
              rank_at( ( RankedModel::MAX_RANK_VALUE + current_order.last.rank ) / 2 )
            else
              rank_at RankedModel::MAX_RANK_VALUE
            end
          when String
            position_at position.to_i
          when 0
            position_at :first
          when Integer
            if current_order[position]
              rank_at( ( current_order[position-1].rank + current_order[position].rank ) / 2 )
            else
              position_at :last
            end
        end
      end

      def assure_unique_position
        if ( new_record? || rank_changed? )
          unless rank
            rank_at RankedModel::MAX_RANK_VALUE
          end

          if (rank > RankedModel::MAX_RANK_VALUE) || (current_order.find do |rankable|
            rankable.rank.nil? ||
            rankable.rank == rank
          end)
            rebalance_ranks
          end
        end
      end

      def rebalance_ranks
        total = current_order.size + 2
        has_set_self = false
        total.times do |index|
          next if index == 0 || index == total
          rank_value = RankedModel::MAX_RANK_VALUE / total * index
          index = index - 1
          if has_set_self
            index = index - 1
          else
            if !current_order[index] ||
               ( !current_order[index].rank.nil? &&
                 current_order[index].rank >= rank )
              rank_at rank_value
              has_set_self = true
              next
            end
          end
          current_order[index].update_rank! rank_value
        end
      end

      def current_order
        @current_order ||= begin
          finder = instance.class
          if ranker.scope
            finder = finder.send ranker.scope
          end
          if ranker.with_same
            finder = finder.where \
              instance.class.arel_table[ranker.with_same].eq(instance.attributes["#{ranker.with_same}"])
          end
          if !new_record?
            finder = finder.where \
              instance.class.arel_table[:id].not_eq(instance.id)
          end
          finder.order(ranker.column).select([:id, ranker.column]).collect { |ordered_instance|
            RankedModel::Ranker::Mapper.new ranker, ordered_instance
          }
        end
      end

    end

  end

end
