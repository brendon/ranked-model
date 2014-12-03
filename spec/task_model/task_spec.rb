require 'spec_helper'

describe Task do
  let(:tasks) do
    tasks = Task.create_tasks_in_same_position(0, 25)
    Task.find(tasks.map(&:id))
  end

  context 'without collision_policy' do
    before do
      Task.class_eval do
        include RankedModel
        ranks :row_order
      end
    end

    it 'use rearrange default collision policy using shift' do
      expect(tasks[-1].row_order).to eq(-8388606)
      expect(tasks[-2].row_order).to eq(tasks[-1].row_order + 1)
      expect(tasks[-3].row_order).to eq(tasks[-2].row_order + 1)
    end
  end

  context 'bad collision_policy' do
    before do
      Task.class_eval do
        include RankedModel
        ranks :row_order, collision_policy: :bad
      end
    end

    it 'use rearrange default collision policy using shift' do
      expect(tasks[-1].row_order).to eq(-8388606)
      expect(tasks[-2].row_order).to eq(tasks[-1].row_order + 1)
      expect(tasks[-3].row_order).to eq(tasks[-2].row_order + 1)
    end
  end

  context 'rearrange collision_policy' do
    before do
      Task.class_eval do
        include RankedModel
        ranks :row_order, collision_policy: :rearrange
      end
    end

    it 'use rearrange collision policy using shift' do
      expect(tasks[-1].row_order).to eq(-8388606)
      expect(tasks[-2].row_order).to eq(tasks[-1].row_order + 1)
      expect(tasks[-3].row_order).to eq(tasks[-2].row_order + 1)
    end
  end

  context 'rebalance collision_policy' do
    before do
      Task.class_eval do
        include RankedModel
        ranks :row_order, collision_policy: :rebalance
      end
    end

    it 'use rearrange collision policy using shift' do
      expect(tasks[-1].row_order).to_not eq(-8388606)
      expect(tasks[-2].row_order).to_not eq(tasks[-1].row_order + 1)
      expect(tasks[-3].row_order).to_not eq(tasks[-2].row_order + 1)
    end
  end

end
