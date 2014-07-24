require 'redis'

redis = Redis.new(:host => '10.11.165.8', :port => 49153)

SCHEDULER.every '5s' do

    ttl = {
        'domains_details' => 0,
        'violation_count_for_domains' => 0,
        'violation_count_by_category_for_domains' => 0,
        'top_violations_in_category_for_domains' => 0,
        'blacklist_domain_count' => 0,
        'most_common_violations' => 0,
        'failed_responses_count' => 0
    }

    ttl.keys().each do |k|
        ttl[k] = redis.ttl(k)
        if ttl[k] < 0
            ttl[k] = redis.ttl("_expired_#{k}")
        end
        send_event(k, {value: ttl[k]})
    end

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
