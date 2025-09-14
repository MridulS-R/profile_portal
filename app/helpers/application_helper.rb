module ApplicationHelper
  def table_exists?(name)
    ActiveRecord::Base.connection.data_source_exists?(name)
  rescue
    false
  end
end

