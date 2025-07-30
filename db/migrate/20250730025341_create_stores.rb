class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.string :name
      t.string :shopify_domain
      t.string :stripe_account_id
      t.string :slack_webhook_url
      t.boolean :active

      t.timestamps
    end
  end
end
