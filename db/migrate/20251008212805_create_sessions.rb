class CreateSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.datetime :first_seen
      t.datetime :last_seen
      t.string :country
      t.string :city
      t.integer :total_clicks, default: 0, null: false
      t.integer :total_time, default: 0, null: false
      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :last_seen
  end
end
