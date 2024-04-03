module OData
  class Query
    # Represents the results of executing a OData::Query.
    # @api private
    class Result
      include Enumerable

      attr_reader :query

      # Initialize a result with the query and the result.
      # @param query [OData::Query]
      # @param result [Typhoeus::Result]
      def initialize(query, result)
        @query      = query
        @result     = result
      end

      # Provided for Enumerable functionality
      # @param block [block] a block to evaluate
      # @return [OData::Entity] each entity in turn for the query result
      MAX_EXECUTIONS = 100
      def each(&block)
        last_processed_url = next_page_url
        process_results(&block)

        finished_processing = last_processed_url == next_page_url
        execution_count = 0
        until finished_processing
          last_processed_url = next_page_url
          result = service.execute(last_processed_url, {}, true)
          process_results(&block)
          execution_count += 1
          finished_processing = next_page.nil? || last_processed_url == next_page_url
          raise 'Possible infinite loop detected' if execution_count > MAX_EXECUTIONS
        end
      end

      private

      attr_accessor :result

      def service
        query.entity_set.service
      end

      def entity_options
        query.entity_set.entity_options
      end

      def process_results(&block)
        service.find_entities(result).each do |entity_xml|
          entity = OData::Entity.from_xml(entity_xml, entity_options)
          block_given? ? block.call(entity) : yield(entity)
        end
      end

      def next_page
        doc = ::Nokogiri::XML(result.body)
        doc.remove_namespaces!
        doc.xpath("/feed/link[@rel='next']").first
      end

      def next_page_url
        return unless next_page && next_page.attributes['href']

        # We used to get the url in http format, then it changed
        # to https. Let's remove both
        http_verison =  service.service_url.sub('https://', 'http://')
        https_version = service.service_url.sub('http://', 'https://')
        next_page.attributes['href']
                 .value
                 .gsub(http_verison, '')
                 .gsub(https_version, '')
      end
    end
  end
end