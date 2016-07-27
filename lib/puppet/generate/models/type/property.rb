require 'puppet/generate/util/helpers'

module Puppet
  module Generate
    module Models
      module Type
        # A model for resource type properties and parameters.
        class Property
          # Gets the name of the property as a Puppet string literal.
          attr_reader :name

          # Gets the Puppet type of the property.
          attr_reader :type

          # Gets the doc string of the property.
          attr_reader :doc

          # Initializes a property model.
          # @param property [Puppet::Property] The Puppet property to model.
          # @return [void]
          def initialize(property)
            @name = Util::to_puppet_string(property.name.to_s)
            @type = self.class.get_puppet_type(property)
            @doc = property.doc.strip
            @is_namevar = property.isnamevar?
          end

          # Determines if this property is a namevar.
          # @return [Boolean] Returns true if the property is a namevar or false if not.
          def is_namevar?
            @is_namevar
          end

          # Gets the Puppet type for a property.
          # @param property [Puppet::Property] The Puppet property to get the Puppet type for.
          # @return [String] Returns the string representing the Puppet type.
          def self.get_puppet_type(property)
            # HACK: the value collection does not expose the underlying value information at all
            #       thus this horribleness to get the underlying values hash
            regexes = []
            strings = []
            values = property.value_collection.instance_variable_get('@values') || {}
            values.each do |_, value|
              if value.regex?
                regexes << "/#{value.name.source.gsub(/\//, '\/')}/"
                next
              end

              strings << Util::to_puppet_string(value.name.to_s)
              value.aliases.each do |a|
                strings << Util::to_puppet_string(a.to_s)
              end
            end

            # If no string or regexes, default to Any type
            return 'Any' if strings.empty? && regexes.empty?

            # Calculate a variant of supported values
            # Note that boolean strings are mapped to Variant[Boolean, Enum['true', 'false']]
            # because of tech debt...
            enum = "Enum[#{strings.join(', ')}]" unless strings.empty?
            pattern = "Pattern[#{regexes.join(', ')}]" unless regexes.empty?
            boolean = 'Boolean' if strings.include?('\'true\'') || strings.include?('\'false\'')
            variant = [boolean, enum, pattern].reject { |t| t.nil? }
            return variant[0] if variant.size == 1
            "Variant[#{variant.join(', ')}]"
          end
        end
      end
    end
  end
end
