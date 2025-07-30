class CreateAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :alerts do |t|
      t.references :store, null: false, foreign_key: true
      t.string :rule_type
      t.string :status
      t.string :severity
      t.string :title
      t.text :description
      t.jsonb :metadata
      t.datetime :resolved_at
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.decimal :money_saved
      t.integer :time_saved
      t.decimal :action_rate

      t.timestamps
    end
  end
end
