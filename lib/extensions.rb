module Extensions
  module Underscore
    def underscore
      self.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
    end
  end

  module Presence
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def present?
      !blank?
    end
  end
end

# apply patches
String.include(Extensions::Underscore)
Symbol.include(Extensions::Underscore)
Object.include(Extensions::Presence)
