require 'redis'

materials = Hash.new({ value: 0 })

redis = Redis.new(:host => '10.11.165.8', :port => 49153)

SCHEDULER.every '2s' do

    domains_details_ttl = redis.ttl('domains_details')
    violation_count_for_domains_ttl = redis.ttl('violation_count_for_domains')
    violation_count_by_category_for_domains_ttl = redis.ttl('violation_count_by_category_for_domains')
    top_violations_in_category_for_domains_ttl = redis.ttl('top_violations_in_category_for_domains')
    blacklist_domain_count_ttl = redis.ttl('blacklist_domain_count')
    most_common_violations_ttl = redis.ttl('most_common_violations')
    failed_responses_count_ttl = redis.ttl('failed_responses_count')

    materials['domains_details_ttl'] = {label: 'domains_details_ttl', value: domains_details_ttl}
    materials['violation_count_for_domains_ttl'] = {label: 'violation_count_for_domains_ttl', value: violation_count_for_domains_ttl}
    materials['violation_count_by_category_for_domains_ttl'] = {label: 'violation_count_by_category_for_domains_ttl', value: violation_count_by_category_for_domains_ttl}
    materials['top_violations_in_category_for_domains_ttl'] = {label: 'top_violations_in_category_for_domains_ttl', value: top_violations_in_category_for_domains_ttl}
    materials['blacklist_domain_count_ttl'] = {label: 'blacklist_domain_count_ttl', value: blacklist_domain_count_ttl}
    materials['most_common_violations_ttl'] = {label: 'most_common_violations_ttl', value: most_common_violations_ttl}
    materials['failed_responses_count_ttl'] = {label: 'failed_responses_count_ttl', value: failed_responses_count_ttl}

    send_event('materials', {items: materials.values})

    all_keys = redis.keys('*')
    locks = all_keys.find_all { |key| key =~ /.+-_LOCK_/ }

    locked_materials = Hash.new({ value: 0 })
    for lock in locks
        lock_ttl = redis.ttl(lock)
        locked_materials[lock] = {label: lock.gsub(/(.+)-_LOCK_/, '\1'), value:lock_ttl}
    end

    send_event('locked_materials', {items: locked_materials.values})

end
