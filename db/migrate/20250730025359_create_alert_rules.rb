class CreateAlertRules < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_rules do |t|
      t.references :store, null: false, foreign_key: true
      t.string :rule_type
      t.string :name
      t.text :description
      t.jsonb :conditions
      t.boolean :enabled
      t.decimal :action_rate
      t.datetime :last_triggered_at

      t.timestamps
    end
  end
end
