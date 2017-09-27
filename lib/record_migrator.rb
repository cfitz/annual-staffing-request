module TwoPointOhMigrator
  
  def to_v2
    request = attributes
    request["request_model_type"] = self.class.name.underscore.split("_").first
    request["organization"]  = department.name
    request.delete("department")
    request["unit"] = unit.name if unit
    attributes.keys.select { |attr| attr =~ /_id$/ }.each do |attr|
      a = attr.remove(/_id$/)
      if self.send(a)
        request[a] = self.send(a.intern).name
      else
        request[a] = nil
      end
      request.delete(attr)
    end
    request
  end

end
