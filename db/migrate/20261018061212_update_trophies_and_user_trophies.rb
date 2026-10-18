class UpdateTrophiesAndUserTrophies < ActiveRecord::Migration[8.0]
  def change
    # trophiesテーブルにcodeカラムを追加し、一意制約を付与
    add_column :trophies, :code, :string
    add_index :trophies, :code, unique: true

    # user_trophiesテーブルに「同じユーザーが同じトロフィーを2回取得できない」一意制約を付与
    add_index :user_trophies, [:user_id, :trophy_id], unique: true
  end
end