require_relative '04_associatable2'

module Validatable

  def validates(name, options)
    @presence = options[:presence]
    @uniqueness = options[:uniqueness]
    @acceptance = options[:acceptance]
  end

  def validate(name, method_name)
  end
end

class SQLObject
  extend Validatable
end
