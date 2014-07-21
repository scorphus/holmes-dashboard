require 'redis'

materials = Hash.new({ value: 0 })

redis = Redis.new(:host => '10.11.165.8', :port => 49153)

SCHEDULER.every '2s' do

    domains_details_ttl = '%02.2f' % (redis.ttl('domains_details') / 3600.0)
    violation_count_for_domains_ttl = '%02.2f' % (redis.ttl('violation_count_for_domains') / 3600.0)
    violation_count_by_category_for_domains_ttl = '%02.2f' % (redis.ttl('violation_count_by_category_for_domains') / 3600.0)
    top_violations_in_category_for_domains_ttl = '%02.2f' % (redis.ttl('top_violations_in_category_for_domains') / 3600.0)
    blacklist_domain_count_ttl = '%02.2f' % (redis.ttl('blacklist_domain_count') / 3600.0)
    most_common_violations_ttl = '%02.2f' % (redis.ttl('most_common_violations') / 3600.0)
    failed_responses_count_ttl = '%02.2f' % (redis.ttl('failed_responses_count') / 3600.0)

    materials['domains_details_ttl'] = {label: 'domains_details_ttl', value: domains_details_ttl}
    materials['violation_count_for_domains_ttl'] = {label: 'violation_count_for_domains_ttl', value: violation_count_for_domains_ttl}
    materials['violation_count_by_category_for_domains_ttl'] = {label: 'violation_count_by_category_for_domains_ttl', value: violation_count_by_category_for_domains_ttl}
    materials['top_violations_in_category_for_domains_ttl'] = {label: 'top_violations_in_category_for_domains_ttl', value: top_violations_in_category_for_domains_ttl}
    materials['blacklist_domain_count_ttl'] = {label: 'blacklist_domain_count_ttl', value: blacklist_domain_count_ttl}
    materials['most_common_violations_ttl'] = {label: 'most_common_violations_ttl', value: most_common_violations_ttl}
    materials['failed_responses_count_ttl'] = {label: 'failed_responses_count_ttl', value: failed_responses_count_ttl}

    send_event('materials', {items: materials.values})

    all_keys = redis.keys('*')
    # locks = all_keys.find_all { |key| key =~ /.+-_LOCK_/ }

    locks = Hash.new({ value: 0 })
    for key in all_keys
        if key =~ /.+-_LOCK_/
            key_ttl = redis.ttl(key)
            locks[key] = {label: key.gsub(/(.+)-_LOCK_/, '\1'), value: '%02.2f' % (key_ttl / 3600.0)}
        end
    end

    send_event('locks', {items: locks.values})

end
