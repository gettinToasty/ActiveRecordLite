require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns
  end

  def self.finalize!
    columns.each do |column|

      define_method("#{column}") do
        self.attributes[column]
      end

      define_method("#{column}=") do |val|
        self.attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name = "#{self.to_s.split(/(?<!^)(?=[A-Z])/).map(&:downcase).join("_")}s"
  end

  def self.all
    hashes = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(hashes)
  end

  def self.parse_all(results)
    arr =[]
    results.each do |result|
      arr << self.new(result)
    end
    arr
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    result.empty? ? nil : self.new(result.first)
  end

  def initialize(params = {})
    params.each do |key, val|
      key = key.to_sym
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key)
      self.send("#{key}=", val)
    end
  end

  def attributes
    @attributes ||= {}
    @attributes
  end

  def attribute_values
    self.class.columns.map { |el| self.send(el) }
  end

  def insert
    col_names = self.class.columns.join(", ")
    marks = []
    self.class.columns.length.times { marks << "?" }
    marks = marks.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{marks})
    SQL
    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns.map{ |name| "#{name}= ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{cols}
      WHERE
        id = ?
    SQL
  end

  def save
    attributes[:id].nil? ? insert : update
  end
end
