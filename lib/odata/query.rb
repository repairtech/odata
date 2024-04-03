module OData
  # OData::Query provides the query interface for requesting Entities matching
  # specific criteria from an OData::EntitySet. This class should not be
  # instantiated directly, but can be. Normally you will access a Query by
  # first asking for one from the OData::EntitySet you want to query.
  class Query
    # Create a new Query for the provided EntitySet
    # @param entity_set [OData::EntitySet]
    def initialize(entity_set)
      @entity_set = entity_set
      setup_empty_criteria_set
    end

    # Instantiates an OData::Query::Criteria for the named property.
    # @param property [to_s]
    def [](property)
      property_instance = @entity_set.new_entity.get_property(property)
      property_instance = property if property_instance.nil?
      OData::Query::Criteria.new(property: property_instance)
    end

    # Adds a filter criteria to the query.
    # For filter syntax see https://msdn.microsoft.com/en-us/library/gg309461.aspx
    # Syntax:
    #   Property Operator Value
    #
    # For example:
    #   Name eq 'Customer Service'
    #
    # Operators:
    # eq, ne, gt, ge, lt, le, and, or, not
    #
    # Value
    #  can be 'null', can use single quotes
    # @param criteria
    def where(criteria)
      criteria_set[:filter] << criteria
      self
    end

    # Adds a filter criteria to the query with 'and' logical operator.
    # @param criteria
    #def and(criteria)
    #
    #end

    # Adds a filter criteria to the query with 'or' logical operator.
    # @param criteria
    #def or(criteria)
    #
    #end

    # Specify properties to order the result by.
    # Can use 'desc' like 'Name desc'
    # @param properties [Array<Symbol>]
    # @return [self]
    def order_by(*properties)
      criteria_set[:orderby] += properties
      self
    end

    # Specify associations to expand in the result.
    # @param associations [Array<Symbol>]
    # @return [self]
    def expand(*associations)
      criteria_set[:expand] += associations
      self
    end

    # Specify properties to select within the result.
    # @param properties [Array<Symbol>]
    # @return [self]
    def select(*properties)
      criteria_set[:select] += properties
      self
    end

    # Add skip criteria to query.
    # @param value [to_i]
    # @return [self]
    def skip(value)
      criteria_set[:skip] = value.to_i
      self
    end

    # Add limit criteria to query.
    # @param value [to_i]
    # @return [self]
    def limit(value)
      criteria_set[:top] = value.to_i
      self
    end

    # Add search term criteria to query.
    # @param value
    # @return [self]
    def search_term(value)
      criteria_set[:search_term] = value
      self
    end

    # Add inline count criteria to query.
    # Not Supported in CRM2011
    # @return [self]
    def include_count
      criteria_set[:inline_count] = true
      self
    end

    # Convert Query to string.
    # @return [String]
    def to_s
      [entity_set.name, assemble_criteria].compact.join('?')
    end

    # Execute the query.
    # @return [OData::Query::Result]
    def execute
      response = entity_set.service.execute(self.to_s)
      OData::Query::Result.new(self, response)
    end

    # Executes the query to get a count of entities.
    # @return [Integer]
    def count
      url_chunk = "#{entity_set.name}/$count?#{assemble_criteria}"
      entity_set.service.execute(url_chunk).body.to_i
    end

    # Checks whether a query will return any results by calling #count
    # @return [Boolean]
    def empty?
      self.count == 0
    end

    # The EntitySet for this query.
    # @return [OData::EntitySet]
    # @api private
    def entity_set
      @entity_set
    end

    private

    def criteria_set
      @criteria_set
    end

    def setup_empty_criteria_set
      @criteria_set = {
          filter:       [],
          select:       [],
          expand:       [],
          orderby:      [],
          skip:         0,
          top:          0,
          inline_count: false,
          search_term:   nil
      }
    end

    def assemble_criteria
      criteria = [
        filter_criteria,
        search_term_criteria(:search_term),
        list_criteria(:orderby),
        list_criteria(:expand),
        list_criteria(:select),
        inline_count_criteria,
        paging_criteria(:skip),
        paging_criteria(:top)
      ].compact!

      criteria.empty? ? nil : criteria.join('&')
    end

    def filter_criteria
      return nil if criteria_set[:filter].empty?
      filters = criteria_set[:filter].collect {|criteria| criteria.to_s}
      "$filter=#{filters.join(' and ')}"
    end

    def list_criteria(name)
      criteria_set[name].empty? ? nil : "$#{name}=#{criteria_set[name].join(',')}"
    end

    # inlinecount not supported by Microsoft CRM 2011
    def inline_count_criteria
      criteria_set[:inline_count] ? '$inlinecount=allpages' : nil
    end

    def search_term_criteria(name)
      search = criteria_set[name].present? == 0 ? nil : "searchTerm='#{criteria_set[name]}'"
      if search.present?
        search += '&includePrerelease=false'
      end
    end

    def paging_criteria(name)
      criteria_set[name] == 0 ? nil : "$#{name}=#{criteria_set[name]}"
    end
  end
end