class CreateAlertActions < ActiveRecord::Migration[8.0]
  def change
    create_table :alert_actions do |t|
      t.references :alert, null: false, foreign_key: true
      t.string :action_type
      t.string :status
      t.jsonb :metadata
      t.datetime :executed_at

      t.timestamps
    end
  end
end
