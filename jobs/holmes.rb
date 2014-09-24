require 'nokogiri'
require 'open-uri'
require 'redis'

grapher_url = 'http://datacenter.globoi.com/grapher.cgi?target=%2Fservers%2Flinux%2Friomp97lb03%2Fnet%2Feth2;ranges=d;view=Octets'

redis = Redis.new(:host => '10.11.165.8', :port => 49153)

keys = %w(domains_details
          violation_count_for_domains
          violation_count_by_category_for_domains
          top_violations_in_category_for_domains
          blacklist_domain_count
          most_common_violations
          failed_responses_count)

max_ttl = 58000.0
ttl = Hash[keys.map{|x| [x, 0]}]

SCHEDULER.every '5s', first_in: 0, allow_overlapping: false do

    # Materials
    keys.each do |k|
        ttl[k] = redis.ttl(k)
        ttl[k] = redis.ttl("_expired_#{k}") if ttl[k] < 0
    end

    holmes_info = ttl.sort_by {|k, v| v}[0..4].inject({}) do |_holmes_info, ttl|
        label = (ttl[0].split(/_/).map(&:chr)).join('').upcase()
        value =  100 * ttl[1] / max_ttl
        _holmes_info[ttl[0]] = {label: label, value: '%02.2f%%' % value}
        _holmes_info
    end

    locked_keys = redis.keys('*_LOCK_')

    locked_keys.each do |key|
        key_name = key.gsub(/-_LOCK_/, '')
        if holmes_info.has_key?(key_name)
            key_ttl = redis.ttl(key)
            holmes_info[key_name][:label] = holmes_info[key_name][:label] + '*'
        end
    end

    # Workers
    grapher = Nokogiri::HTML(open(grapher_url))
    tds = grapher.xpath('.//td[contains(.,"Average bits out")]')

    bits_in = tds[0].content.match(/cur: ([0-9]+)/i)[1].to_i / 1048576.0
    bits_out = tds[1].content.match(/cur: ([0-9]+)/i)[1].to_i / 1048576.0

    holmes_info['bits_in'] = {label: 'MB/s in', value: '%02.2f' % bits_in}
    holmes_info['bits_out'] = {label: 'MB/s out', value: '%02.2f' % bits_out}

    send_event('holmes', {items: holmes_info.values})

end
