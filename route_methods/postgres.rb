require 'pg'
#require_relative '../secrets'

class PostGres
  def db_query_user(table, user)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    user = @con.exec "SELECT * FROM #{table} where name=\'#{user}\'"
    @con.close
    return false if user.count.zero?
    return false if user.count >= 2
    user[0]
  end

  def db_generic_query(table, column, value)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    query_data = @con.exec "SELECT * FROM #{table} where #{column}=\'#{value}\'"
    @con.close
    return false if query_data.count.zero?
    data = []
    query_data.each do |row|
      data << row
    end
    data
  end

  def db_generic_query_advance(table, where_query, select_items = '*')
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    query_data = @con.exec "SELECT #{select_items} FROM #{table} #{where_query}"
    @con.close
    return false if query_data.count.zero?
    data = []
    query_data.each do |row|
      data << row
    end
    data
  end

  def db_insert_data(table, columns, values)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    user = @con.exec "INSERT INTO #{table} (#{columns}) VALUES(#{values})"
    @con.close
    return false if user.nil? || user.to_s.empty?
    true
  end

  # single field
  def update_table_field(table, column, new_value, ref_column, ref_value)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    update = @con.exec "UPDATE #{table} SET #{column}=\'#{new_value}\' WHERE #{ref_column}=\'#{ref_value}\'"
    @con.close
    return false if update.nil? || update.to_s.empty?
    true
  end

  # multi fields
  def update_table_fields(table, column_to_values, ref_column, ref_value)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    update = @con.exec "UPDATE #{table} SET #{column_to_values} WHERE #{ref_column}=\'#{ref_value}\'"
    @con.close
    return false if update.nil? || update.to_s.empty?
    true
  end

  def create_table(table_name, columns)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    new_table = @con.exec "CREATE TABLE #{table_name}(#{columns})" # colums eg (name varchar(16) PRIMARY KEY UNIQUE, password varchar(32))
    @con.close
    return false if new_table.nil? || new_table.to_s.empty?
    true
  end

  def get_table_hash(table_name)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    table = @con.exec "SELECT * FROM #{table_name}"
    @con.close
    return false if table.nil? || table.to_s.empty?
    table_hash = []
    table.each do |row|
      table_hash << row
    end
    table_hash
  end

  def delete_table_row(table_name, column, value)
    @con = PG.connect :hostaddr => ENV['db_hostaddress'], :dbname => ENV['db_name'], :user => ENV['db_username'], :password => ENV['db_password']
    delete = @con.exec "DELETE FROM #{table_name} WHERE #{column}=\'#{value}\'"
    @con.close
    return false if delete.nil? || delete.to_s.empty?
    true
  end
end
