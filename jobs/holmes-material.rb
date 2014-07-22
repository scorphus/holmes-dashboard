require 'redis'

materials = Hash.new({ value: 0 })

redis = Redis.new(:host => '10.11.165.8', :port => 49153)

SCHEDULER.every '5s' do

    domains_details_ttl = redis.ttl('domains_details')
    violation_count_for_domains_ttl = redis.ttl('violation_count_for_domains')
    violation_count_by_category_for_domains_ttl = redis.ttl('violation_count_by_category_for_domains')
    top_violations_in_category_for_domains_ttl = redis.ttl('top_violations_in_category_for_domains')
    blacklist_domain_count_ttl = redis.ttl('blacklist_domain_count')
    most_common_violations_ttl = redis.ttl('most_common_violations')
    failed_responses_count_ttl = redis.ttl('failed_responses_count')

    send_event('domains_details_ttl', {value: domains_details_ttl})
    send_event('violation_count_for_domains_ttl', {value: violation_count_for_domains_ttl})
    send_event('violation_count_by_category_for_domains_ttl', {value: violation_count_by_category_for_domains_ttl})
    send_event('top_violations_in_category_for_domains_ttl', {value: top_violations_in_category_for_domains_ttl})
    send_event('blacklist_domain_count_ttl', {value: blacklist_domain_count_ttl})
    send_event('most_common_violations_ttl', {value: most_common_violations_ttl})
    send_event('failed_responses_count_ttl', {value: failed_responses_count_ttl})

    all_keys = redis.keys('*')

    locks = Hash.new({ value: 0 })
    for key in all_keys
        if key =~ /.+-_LOCK_/
            key_ttl = redis.ttl(key)
            label = (key.gsub(/(.+)-_LOCK_/, '\1').split(/_/).map {|l| l[0]}).join('').upcase()
            locks[key] = {label: label, value: '%02.2f' % (key_ttl / 60.0)}
        end
    end

    send_event('locks', {items: locks.values})

end
