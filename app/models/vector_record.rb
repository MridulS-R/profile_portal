# frozen_string_literal: true

class VectorRecord < ApplicationRecord
  self.table_name = 'vision_vectors'

  # Build a SQL literal for pgvector from Ruby array
  def self.vector_sql_literal(vec)
    vals = Array(vec).map { |x| format('%.6f', x.to_f) }.join(',')
    "'[#{vals}]'"
  end

  def self.order_by_cosine(vec)
    lit = vector_sql_literal(vec)
    order(Arel.sql("embedding <=> #{lit} ASC"))
  end

  def self.order_by_l2(vec)
    lit = vector_sql_literal(vec)
    order(Arel.sql("embedding <-> #{lit} ASC"))
  end

  def self.order_by_dot(vec)
    lit = vector_sql_literal(vec)
    order(Arel.sql("embedding <#> #{lit} ASC"))
  end
end

