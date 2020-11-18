module RankedModel

  class InvalidScope < StandardError; end
  class InvalidField < StandardError; end

  class Ranker
    attr_accessor :name, :column, :scope, :with_same, :class_name, :unless

    def initialize name, options={}
      self.name = name.to_sym
      self.column = options[:column] || name
      self.class_name = options[:class_name]

      [ :scope, :with_same, :unless ].each do |key|
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
        if ranker.scope && !instance_class.respond_to?(ranker.scope)
          raise RankedModel::InvalidScope, %Q{No scope called "#{ranker.scope}" found in model}
        end

        if ranker.with_same
          if (case ranker.with_same
                when Symbol
                  !instance.respond_to?(ranker.with_same)
                when Array
                  array_element = ranker.with_same.detect {|attr| !instance.respond_to?(attr) }
                else
                  false
              end)
            raise RankedModel::InvalidField, %Q{No field called "#{array_element || ranker.with_same}" found in model}
          end
        end
      end

      def handle_ranking
        case ranker.unless
        when Proc
          return if ranker.unless.call(instance)
        when Symbol
          return if instance.send(ranker.unless)
        end

        update_index_from_position
        assure_unique_position
      end

      def update_rank! value
        # Bypass callbacks
        #
        instance_class.
          where(instance_class.primary_key => instance.id).
          update_all(ranker.column => value)
      end

      def reset_ranks!
        finder.update_all(ranker.column => nil)
      end

      def position
        instance.send "#{ranker.name}_position"
      end

      def relative_rank
        escaped_column = instance_class.connection.quote_column_name ranker.column

        finder.where("#{escaped_column} < #{rank}").count(:all)
      end

      def rank
        instance.send "#{ranker.column}"
      end

      def current_at_position _pos
        if (ordered_instance = finder.offset(_pos).first)
          RankedModel::Ranker::Mapper.new ranker, ordered_instance
        end
      end

      def has_rank?
        !rank.nil?
      end

    private

      def reset_cache
        @finder, @current_order, @current_first, @current_last = nil
      end

      def instance_class
        ranker.class_name.nil? ? instance.class : ranker.class_name.constantize
      end

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
          when :first, 'first'
            if current_first && current_first.rank
              rank_at_average current_first.rank, RankedModel::MIN_RANK_VALUE
            else
              position_at :middle
            end
          when :last, 'last'
            if current_last && current_last.rank
              rank_at_average current_last.rank, RankedModel::MAX_RANK_VALUE
            else
              position_at :middle
            end
          when :middle, 'middle'
            rank_at_average RankedModel::MIN_RANK_VALUE, RankedModel::MAX_RANK_VALUE
          when :down, 'down'
            neighbors = find_next_two(rank)
            if neighbors[:lower]
              min = neighbors[:lower].rank
              max = neighbors[:upper] ? neighbors[:upper].rank : RankedModel::MAX_RANK_VALUE
              rank_at_average min, max
            end
          when :up, 'up'
            neighbors = find_previous_two(rank)
            if neighbors[:upper]
              max = neighbors[:upper].rank
              min = neighbors[:lower] ? neighbors[:lower].rank : RankedModel::MIN_RANK_VALUE
              rank_at_average min, max
            end
          when String
            position_at position.to_i
          when 0
            position_at :first
          when Integer
            neighbors = neighbors_at_position(position)
            min = ((neighbors[:lower] && neighbors[:lower].has_rank?) ? neighbors[:lower].rank : RankedModel::MIN_RANK_VALUE)
            max = ((neighbors[:upper] && neighbors[:upper].has_rank?) ? neighbors[:upper].rank : RankedModel::MAX_RANK_VALUE)
            rank_at_average min, max
          when NilClass
            if !rank
              position_at :last
            end
        end
      end

      def rank_at_average(min, max)
        if (max - min).between?(-1, 1) # No room at the inn...
          rebalance_ranks
          position_at position
        else
          rank_at( ( ( max - min ).to_f / 2 ).ceil + min )
        end
      end

      def assure_unique_position
        if ( new_record? || rank_changed? )
          if (rank > RankedModel::MAX_RANK_VALUE) || rank_taken?
            rearrange_ranks
          end
        end
      end

      def rearrange_ranks
        _scope = finder
        escaped_column = instance_class.connection.quote_column_name ranker.column
        # If there is room at the bottom of the list and we're added to the very top of the list...
        if current_first.rank && current_first.rank > RankedModel::MIN_RANK_VALUE && rank == RankedModel::MAX_RANK_VALUE
          # ...then move everyone else down 1 to make room for us at the end
          _scope.
            where( instance_class.arel_table[ranker.column].lteq(rank) ).
            update_all( "#{escaped_column} = #{escaped_column} - 1" )
        # If there is room at the top of the list and we're added below the last value in the list...
        elsif current_last.rank && current_last.rank < (RankedModel::MAX_RANK_VALUE - 1) && rank < current_last.rank
          # ...then move everyone else at or above our desired rank up 1 to make room for us
          _scope.
            where( instance_class.arel_table[ranker.column].gteq(rank) ).
            update_all( "#{escaped_column} = #{escaped_column} + 1" )
        # If there is room at the bottom of the list and we're added above the lowest value in the list...
        elsif current_first.rank && current_first.rank > RankedModel::MIN_RANK_VALUE && rank > current_first.rank
          # ...then move everyone else below us down 1 and change our rank down 1 to avoid the collission
          _scope.
            where( instance_class.arel_table[ranker.column].lt(rank) ).
            update_all( "#{escaped_column} = #{escaped_column} - 1" )
          rank_at( rank - 1 )
        else
          rebalance_ranks
        end
      end

      def rebalance_ranks
        ActiveRecord::Base.transaction do
          if rank && instance.persisted?
            origin = current_order.index { |item| item.instance.id == instance.id }
            if origin
              destination = current_order.index { |item| rank <= item.rank }
              destination -= 1 if origin < destination

              current_order.insert destination, current_order.delete_at(origin)
            end
          end

          gaps = current_order.size + 1
          range = (RankedModel::MAX_RANK_VALUE - RankedModel::MIN_RANK_VALUE).to_f
          gap_size = (range / gaps).ceil

          reset_ranks!

          current_order.each.with_index(1) do |item, position|
            new_rank = (gap_size * position) + RankedModel::MIN_RANK_VALUE

            if item.instance.id == instance.id
              rank_at new_rank
            else
              item.update_rank! new_rank
            end
          end

          reset_cache
        end
      end

      def finder(order = :asc)
        @finder ||= {}
        @finder[order] ||= begin
          _finder = instance_class
          columns = [instance_class.primary_key.to_sym, ranker.column]

          if ranker.scope
            _finder = _finder.send ranker.scope
          end

          case ranker.with_same
          when Symbol
            columns << ranker.with_same
            _finder = _finder.where \
              ranker.with_same => instance.attributes[ranker.with_same.to_s]
          when Array
            ranker.with_same.each do |column|
              columns << column
              _finder = _finder.where column => instance.attributes[column.to_s]
            end
          end

          unless new_record?
            _finder = _finder.where.not instance_class.primary_key.to_sym => instance.id
          end

          _finder.reorder(ranker.column.to_sym => order).select(columns)
        end
      end

      def current_order
        @current_order ||= begin
          finder.unscope(where: instance_class.primary_key.to_sym).collect { |ordered_instance|
            RankedModel::Ranker::Mapper.new ranker, ordered_instance
          }
        end
      end

      def current_first
        @current_first ||= begin
          if (ordered_instance = finder.first)
            RankedModel::Ranker::Mapper.new ranker, ordered_instance
          end
        end
      end

      def current_last
        @current_last ||= begin
          if (ordered_instance = finder.
                                   reverse.
                                   first)
            RankedModel::Ranker::Mapper.new ranker, ordered_instance
          end
        end
      end

      def rank_taken?
        finder.except(:order).where(ranker.column => rank).exists?
      end

      def neighbors_at_position _pos
        if _pos > 0
          if (ordered_instances = finder.offset(_pos-1).limit(2).to_a)
            if ordered_instances[1]
              { :lower => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[0] ),
                :upper => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[1] ) }
            elsif ordered_instances[0]
              { :lower => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[0] ) }
            else
              { :lower => current_last }
            end
          end
        else
          if (ordered_instance = finder.first)
            { :upper => RankedModel::Ranker::Mapper.new( ranker, ordered_instance ) }
          else
            {}
          end
        end
      end

      def find_next_two _rank
        ordered_instances = finder.where(instance_class.arel_table[ranker.column].gt _rank).limit(2)
        if ordered_instances[1]
          { :lower => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[0] ),
            :upper => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[1] ) }
        elsif ordered_instances[0]
          { :lower => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[0] ) }
        else
          {}
        end
      end

      def find_previous_two _rank
        ordered_instances = finder(:desc).where(instance_class.arel_table[ranker.column].lt _rank).limit(2)
        if ordered_instances[1]
          { :upper => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[0] ),
            :lower => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[1] ) }
        elsif ordered_instances[0]
          { :upper => RankedModel::Ranker::Mapper.new( ranker, ordered_instances[0] ) }
        else
          {}
        end
      end

    end

  end

end
