class FixUserLevelsBasedOnNewExp < ActiveRecord::Migration[8.1]
  def up
    User.find_each do |user|
      correct_level = 1
      while user.exp >= user.total_exp_required_for_level(correct_level + 1)
        correct_level += 1
      end
      user.update!(level: correct_level)
    end
  end

  def down
    # 過去のレベルに戻すのは難しいため空のままでOK
  end
end
