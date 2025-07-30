class CreateWebhookEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_events do |t|
      t.references :store, null: false, foreign_key: true
      t.string :event_type
      t.jsonb :payload
      t.boolean :processed
      t.datetime :processed_at

      t.timestamps
    end
  end
end
