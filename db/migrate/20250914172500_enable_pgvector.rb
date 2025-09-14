# frozen_string_literal: true

class EnablePgvector < ActiveRecord::Migration[7.1]
  def up
    enable_extension "vector"
  rescue ActiveRecord::StatementInvalid => e
    raise StandardError, <<~MSG
      pgvector extension is not installed for your PostgreSQL.

      Install it, then rerun migrations. For macOS (Homebrew, Postgres 14):

        brew install postgresql@14 # if not already
        git clone https://github.com/pgvector/pgvector.git
        cd pgvector
        make PG_CONFIG=/opt/homebrew/opt/postgresql@14/bin/pg_config
        make PG_CONFIG=/opt/homebrew/opt/postgresql@14/bin/pg_config install

      Verify with:
        ls $(/opt/homebrew/opt/postgresql@14/bin/pg_config --sharedir)/extension/vector*

      Then run:
        bin/rails db:migrate

      Original error: #{e.message}
    MSG
  end

  def down
    disable_extension "vector"
  end
end
