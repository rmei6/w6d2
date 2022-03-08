require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    return @columns.first.map{|column| column.to_sym}
  end

  def self.finalize!
    columns.each do |column|
      #debugger
      define_method(column) do 
        return self.attributes[column]
      end
      define_method("#{column}=") do |val|
        self.attributes[column] = val 
      end
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
    
  end

  def self.table_name
    # ...
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # ...
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    # ...
    humans = []
    results.each do |result|
      humans << self.new(result)
    end
    humans
  end

  def self.find(id)
    # ...
    result = DBConnection.execute(<<-SQL,id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
      LIMIT
        1
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    # ...
    col = self.class.columns
    params.each do |attr_name,value|
      raise "unknown attribute '#{attr_name}'" unless col.include?(attr_name.to_sym)
      #debugger
      self.send("#{attr_name}=".to_sym,value)
    end
  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map {|col| self.attributes[col]}
  end

  def insert
    # ...
    col_names = self.class.columns.join(",")
    values = attribute_values
    question_marks = ['?'] * values.length
    DBConnection.execute(<<-SQL,*values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks.join(",")})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    # col_names = self.class.columns.join(",")
    set_line = self.class.columns.map {|attr_name| "#{attr_name} = ?"}.join(",")
    values = attribute_values
    DBConnection.execute(<<-SQL,values,self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
      SQL
  end

  def save
    # ...
    if id.nil?
      insert
    else
      update
    end 
  end
end
