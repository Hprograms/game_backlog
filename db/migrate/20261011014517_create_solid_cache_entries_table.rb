class CreateSolidCacheEntriesTable < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cache_entries, if_not_exists: true do |t|
      t.binary   :key,        null: false, limit: 1024
      t.binary   :value,      null: false, limit: 512.megabytes
      t.datetime :created_at, null: false
      t.integer  :key_hash,   null: false, limit: 8
      t.integer  :byte_size,  null: false
      
      t.index [:key_hash, :byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
      t.index [:key_hash], name: "index_solid_cache_entries_on_key_hash", unique: true
      t.index [:byte_size], name: "index_solid_cache_entries_on_byte_size"
    end
  end
end
