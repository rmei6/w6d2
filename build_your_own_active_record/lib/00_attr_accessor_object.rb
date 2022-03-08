require 'byebug'
class AttrAccessorObject
  def self.my_attr_accessor(*names)
    # ...
    names.each do |name|
      #debugger
      define_method(name) do 
        return self.instance_variable_get("@#{name}")
      end
      define_method("#{name}=") do |val|
        self.instance_variable_set("@#{name}",val)
      end
    end
  end
end
