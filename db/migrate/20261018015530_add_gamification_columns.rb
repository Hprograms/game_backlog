class AddGamificationColumns < ActiveRecord::Migration[8.0]
  def change
    # usersテーブルへ追加
    add_column :users, :level, :integer, default: 1, null: false
    add_column :users, :exp, :integer, default: 0, null: false
    
    # gamesテーブルへ追加（経験値の二重取り防止フラグ）
    add_column :games, :exp_awarded_for_clear, :boolean, default: false, null: false
  end
end