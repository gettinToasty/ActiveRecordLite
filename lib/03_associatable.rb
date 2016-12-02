require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor :foreign_key, :class_name, :primary_key

  def model_class
    @name.to_s.camelcase.singularize.constantize
  end

  def table_name
    @name[-2] == "a" ? "#{@name}s" : @name.to_s.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end

  def foreign_key
    @foreign_key ||= "#{@name.to_s.underscore.singularize}_id".to_sym
  end

  def primary_key
    @primary_key ||= :id
  end

  def class_name
    @class_name ||= @name.to_s.camelcase.singularize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @s_name = self_class_name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end

  def foreign_key
    @foreign_key ||= "#{@s_name.to_s.singularize.underscore}_id".to_sym
  end

  def primary_key
    @primary_key ||= :id
  end

  def class_name
    @class_name ||= @name.to_s.camelcase.singularize
  end

end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(options.table_name.singularize) do
      foreign = self.send("#{options.foreign_key}")
      class_name = options.model_class
      class_name.where(id: foreign).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(options.table_name) do
      primary = self.send("#{options.primary_key}")
      class_name = options.model_class
      class_name.where(options.foreign_key => primary)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
