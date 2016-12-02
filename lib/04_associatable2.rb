require_relative '03_associatable'

module Associatable

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      foreign_key = self.send(through_options.foreign_key)
      class_name = source_options.model_class
      
      class_name.where(id: foreign_key).first
    end
  end
end
