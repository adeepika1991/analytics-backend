class CreateEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string :session_id, null: false, index: true
      t.string :event_type, null: false, index: true
      t.jsonb :data, default: {}
      t.string :url
      t.string :referrer
      t.text :user_agent
      t.datetime :event_timestamp
      t.timestamps
    end

    add_index :events, [:created_at]
  end
end
