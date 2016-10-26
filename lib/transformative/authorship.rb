module Transformative
  module Authorship
    module_function

    def fetch(url)
      return unless Utils.valid_url?(url)
      get_author(url)
    end

    def get_author(url, body=nil)
      body ||= HTTParty.get(url).body
      json = Microformats2.parse(body).to_json
      items = JSON.parse(json)['items']

      # find first h-entry
      entry = find_first_hentry(items)
      if entry.nil?
        raise AuthorshipError.new("No h-entry found at #{url}.")
      end

      # find author in the entry or on the page
      author = find_author(entry)
      return if author.nil?

      # find author properties
      if author.is_a?(Hash) && author['type'][0] == 'h-card'
        construct_author_hcard(author)
      elsif author.is_a?(String) && Utils.valid_url?(author)
        get_author_hcard(author)
      end
    end

    def find_first_hentry(items)
      items.each do |item|
        if item['type'][0] == 'h-entry'
          return item
        end
      end
    end

    def find_author(entry)
      if entry['properties'].key?('author')
        entry['properties']['author'][0]
      elsif author_rel = Nokogiri::HTML(body).css("[rel=author]")
        author_rel.attribute('href').value
      end
    end

    def construct_author_hcard(author)
      url = "/cards/#{Utils.slugify_url(author['properties']['url'][0])}"
      Card.new(author['properties'], url)
    end

    def get_author_hcard(url)
      body = HTTParty.get(url).body
      json = Microformats2.parse(body).to_json
      properties = JSON.parse(json)['items'][0]['properties']
      card_url = "/cards/#{Utils.slugify_url(url)}"
      Card.new(properties, card_url)
    end

  end
end