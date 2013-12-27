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
                  ranker.with_same.detect {|attr| !instance.respond_to?(attr) }
                else
                  false
              end)
            raise RankedModel::InvalidField, %Q{No field called "#{ranker.with_same}" found in model}
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
          update_all([%Q{#{ranker.column} = ?}, value])
      end

      def position
        instance.send "#{ranker.name}_position"
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
              rank_at( ( ( RankedModel::MIN_RANK_VALUE - current_first.rank ).to_f / 2 ).ceil + current_first.rank)
            else
              position_at :middle
            end
          when :last, 'last'
            if current_last && current_last.rank
              rank_at( ( ( RankedModel::MAX_RANK_VALUE - current_last.rank ).to_f / 2 ).ceil + current_last.rank )
            else
              position_at :middle
            end
          when :middle, 'middle'
            rank_at( ( ( RankedModel::MAX_RANK_VALUE - RankedModel::MIN_RANK_VALUE ).to_f / 2 ).ceil + RankedModel::MIN_RANK_VALUE )
          when :down, 'down'
            neighbors = find_next_two(rank)
            if neighbors[:lower]
              min = neighbors[:lower].rank
              max = neighbors[:upper] ? neighbors[:upper].rank : RankedModel::MAX_RANK_VALUE
              rank_at( ( ( max - min ).to_f / 2 ).ceil + min )
            end
          when :up, 'up'
            neighbors = find_previous_two(rank)
            if neighbors[:upper]
              max = neighbors[:upper].rank
              min = neighbors[:lower] ? neighbors[:lower].rank : RankedModel::MIN_RANK_VALUE
              rank_at( ( ( max - min ).to_f / 2 ).ceil + min )
            end
          when String
            position_at position.to_i
          when 0
            position_at :first
          when Integer
            neighbors = neighbors_at_position(position)
            min = ((neighbors[:lower] && neighbors[:lower].has_rank?) ? neighbors[:lower].rank : RankedModel::MIN_RANK_VALUE)
            max = ((neighbors[:upper] && neighbors[:upper].has_rank?) ? neighbors[:upper].rank : RankedModel::MAX_RANK_VALUE)
            rank_at( ( ( max - min ).to_f / 2 ).ceil + min )
          when NilClass
            if !rank
              position_at :last
            end
        end
      end

      def assure_unique_position
        if ( new_record? || rank_changed? )
          unless rank
            rank_at( RankedModel::MAX_RANK_VALUE )
          end

          if (rank > RankedModel::MAX_RANK_VALUE) || current_at_rank(rank)
            rearrange_ranks
          end
        end
      end

      def rearrange_ranks
        _scope = finder
        unless instance.id.nil?
          # Never update ourself, shift others around us.
          _scope = _scope.where( instance_class.arel_table[instance_class.primary_key].not_eq(instance.id) )
        end
        if current_first.rank && current_first.rank > RankedModel::MIN_RANK_VALUE && rank == RankedModel::MAX_RANK_VALUE
          _scope.
            where( instance_class.arel_table[ranker.column].lteq(rank) ).
            update_all( %Q{#{ranker.column} = #{ranker.column} - 1} )
        elsif current_last.rank && current_last.rank < (RankedModel::MAX_RANK_VALUE - 1) && rank < current_last.rank
          _scope.
            where( instance_class.arel_table[ranker.column].gteq(rank) ).
            update_all( %Q{#{ranker.column} = #{ranker.column} + 1} )
        elsif current_first.rank && current_first.rank > RankedModel::MIN_RANK_VALUE && rank > current_first.rank
          _scope.
            where( instance_class.arel_table[ranker.column].lt(rank) ).
            update_all( %Q{#{ranker.column} = #{ranker.column} - 1} )
          rank_at( rank - 1 )
        else
          rebalance_ranks
        end
      end

      def rebalance_ranks
        total = current_order.size + 2
        has_set_self = false
        total.times do |index|
          next if index == 0 || index == total
          rank_value = ((((RankedModel::MAX_RANK_VALUE - RankedModel::MIN_RANK_VALUE).to_f / total) * index ).ceil + RankedModel::MIN_RANK_VALUE)
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

      def finder(order = :asc)
        @finder ||= begin
          _finder = instance_class
          columns = [instance_class.arel_table[instance_class.primary_key], instance_class.arel_table[ranker.column]]
          if ranker.scope
            _finder = _finder.send ranker.scope
          end
          case ranker.with_same
            when Symbol
              columns << instance_class.arel_table[ranker.with_same]
              _finder = _finder.where \
                instance_class.arel_table[ranker.with_same].eq(instance.attributes["#{ranker.with_same}"])
            when Array
              ranker.with_same.each {|c| columns.push instance_class.arel_table[c] }
              _finder = _finder.where(
                ranker.with_same[1..-1].inject(
                  instance_class.arel_table[ranker.with_same.first].eq(
                    instance.attributes["#{ranker.with_same.first}"]
                  )
                ) {|scoper, attr|
                  scoper.and(
                    instance_class.arel_table[attr].eq(
                      instance.attributes["#{attr}"]
                    )
                  )
                }
              )
          end
          if !new_record?
            _finder = _finder.where \
              instance_class.arel_table[instance_class.primary_key].not_eq(instance.id)
          end
          _finder.order(instance_class.arel_table[ranker.column].send(order)).select(columns)
        end
      end

      def current_order
        @current_order ||= begin
          finder.collect { |ordered_instance|
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

      def current_at_rank _rank
        if (ordered_instance = finder.
                                 except( :order ).
                                 where( ranker.column => _rank ).
                                 first)
          RankedModel::Ranker::Mapper.new ranker, ordered_instance
        end
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
