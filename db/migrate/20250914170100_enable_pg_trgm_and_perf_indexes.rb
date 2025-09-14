class EnablePgTrgmAndPerfIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    # Partial unique index for github_username (non-null usernames should be unique)
    unless index_exists?(:users, :github_username, unique: true, where: "github_username IS NOT NULL")
      add_index :users, :github_username, unique: true, algorithm: :concurrently, where: "github_username IS NOT NULL", name: "index_users_on_github_username_unique"
    end

    # Trigram indexes to speed up ILIKE queries on projects search
    unless index_exists?(:projects, :repo_full_name, using: :gin, name: "index_projects_on_repo_full_name_trgm")
      execute "CREATE INDEX CONCURRENTLY index_projects_on_repo_full_name_trgm ON projects USING gin (repo_full_name gin_trgm_ops)"
    end
    unless index_exists?(:projects, :description, using: :gin, name: "index_projects_on_description_trgm")
      execute "CREATE INDEX CONCURRENTLY index_projects_on_description_trgm ON projects USING gin (description gin_trgm_ops)"
    end

    # Support ordering by stars within a user's projects
    unless index_exists?(:projects, [:user_id, :stars], name: "index_projects_on_user_id_and_stars_desc")
      add_index :projects, [:user_id, :stars], order: { stars: :desc }, algorithm: :concurrently, name: "index_projects_on_user_id_and_stars_desc"
    end
  end

  def down
    remove_index :projects, name: "index_projects_on_user_id_and_stars_desc" if index_exists?(:projects, name: "index_projects_on_user_id_and_stars_desc")
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_projects_on_description_trgm"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_projects_on_repo_full_name_trgm"
    remove_index :users, name: "index_users_on_github_username_unique" if index_exists?(:users, name: "index_users_on_github_username_unique")
    disable_extension 'pg_trgm' if extension_enabled?('pg_trgm')
  end
end

