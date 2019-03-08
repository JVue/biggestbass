require_relative 'postgres'

class User
  attr_reader :name, :password

  def initialize(name, password)
    @pg = PostGres.new
    @name = name
    @password = password
  end

  def create_user(name, password)
    @pg.db_insert_data('users', 'name, password', "\'#{name}\', \'#{password}\'")
  end

  def authorized?(name = @name)
    user_info = @pg.db_query_user('users', name)
    return false if user_info.nil? || user_info.to_s.empty? || user_info.count.zero?
    return false if user_info['password'] != @password
    true
  rescue
    false
  end

  def delete_user(name = @name)
    delete_table_row('users', 'name', name)
  end

  def change_password(new_password, name = @name)
    @pg.update_table_field('users', 'password', new_password, 'name', name)
  end
end
