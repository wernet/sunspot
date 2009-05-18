module Sunspot
  # 
  # This module contains singleton objects that represent the types that can be
  # indexed and searched using Sunspot. Plugin developers should be able to
  # add new constants to the Type module; as long as they implement the
  # appropriate methods, Sunspot should be able to integrate them (note that
  # this capability is untested at the moment). The required methods are:
  #
  # +indexed_name+::
  #   Convert a given field name into its form as stored in Solr. This
  #   generally means adding a suffix to match a Solr dynamicField definition.
  # +to_indexed+::
  #   Convert a value of this type into the appropriate Solr string
  #   representation.
  # +cast+::
  #   Convert a Solr string representation of a value into the appropriate
  #   Ruby type.
  #
  module Type
    NATIVE_TYPE_CACHE = {}

    class <<self
      def for_value(value)
        NATIVE_TYPE_CACHE.each_pair do |native_type, type|
          return type if value.is_a?(native_type)
        end
        Type::StringType
      end
    end

    module HandlesNative
      def handles_native(*classes)
        for clazz in classes
          NATIVE_TYPE_CACHE[clazz] = self
        end
      end
    end

    # 
    # Text is a special type that stores data for fulltext search. Unlike other
    # types, Text fields are tokenized and are made available to the keyword
    # search phrase. Text fields cannot be faceted, ordered upon, or used in
    # restrictions. Similarly, text fields are the only fields that are made
    # available to keyword search.
    #
    module TextType
      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_text"
        end

        def to_indexed(value) #:nodoc:
          value.to_s if value
        end
      end
    end

    # 
    # The String type represents string data.
    #
    module StringType
      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_s"
        end

        def to_indexed(value) #:nodoc:
          value.to_s if value
        end

        def cast(string) #:nodoc:
          string
        end
      end
    end

    # 
    # The Integer type represents integers.
    #
    module IntegerType
      extend HandlesNative
      handles_native Integer

      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_i"
        end

        def to_indexed(value) #:nodoc:
          value.to_i.to_s if value
        end

        def cast(string) #:nodoc:
          string.to_i
        end
      end
    end

    # 
    # The Float type represents floating-point numbers.
    #
    module FloatType
      extend HandlesNative
      handles_native Float

      class <<self
        def indexed_name(name) #:nodoc:
        "#{name}_f"
        end

        def to_indexed(value) #:nodoc:
          value.to_f.to_s if value
        end

        def cast(string) #:nodoc:
          string.to_f
        end
      end
    end

    # 
    # The time type represents times. Note that times are always converted to
    # UTC before indexing, and facets of Time fields always return times in UTC.
    #
    module TimeType
      extend HandlesNative
      handles_native Date, Time

      class <<self
        def indexed_name(name)
        "#{name}_d"
        end

        def to_indexed(value)
          if value
            time =
              if value.respond_to?(:utc)
                value
              elsif %w(year mon mday).each { |method| value.respond_to?(method) }
                Time.gm(value.year, value.mon, value.mday)
              else
                Time.parse(value.to_s)
              end
            time.utc.xmlschema
          end
        end

        def cast(string)
          Time.xmlschema(string)
        end
      end
    end

    # 
    # The boolean type represents true/false values. Note that +nil+ will not be
    # indexed at all; only +false+ will be indexed with a false value.
    #
    module BooleanType
      extend HandlesNative
      handles_native TrueClass, FalseClass

      class <<self
        def indexed_name(name)
        "#{name}_b"
        end

        def to_indexed(value)
          unless value.nil?
            value ? 'true' : 'false'
          end
        end

        def cast(string)
          case string
          when 'true'
            true
          when 'false'
            false
          end
        end
      end
    end
  end
end
