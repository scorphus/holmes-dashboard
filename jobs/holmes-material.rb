require 'redis'

redis = Redis.new(:host => '10.11.165.8', :port => 49153)

keys = %w(domains_details
          violation_count_for_domains
          violation_count_by_category_for_domains
          top_violations_in_category_for_domains
          blacklist_domain_count
          most_common_violations
          failed_responses_count)

ttl = Hash[keys.map{|x| [x, 0]}]

SCHEDULER.every '5s', first_in: 0, allow_overlapping: false do
    keys.each do |k|
        ttl[k] = redis.ttl(k)
        ttl[k] = redis.ttl("_expired_#{k}") if ttl[k] < 0
        send_event(k, {value: ttl[k]})
    end

    locked_keys = redis.keys('*_LOCK_')

    locks = locked_keys.inject({}) do |_locks, key|
        key_ttl = redis.ttl(key)
        label = (key.gsub(/_LOCK_/, '').split(/_/).map(&:chr)).join('').upcase()
        _locks[key] = {label: label, value: '%02.2f' % (key_ttl / 60.0)}
        _locks
    end

    send_event('locks', {items: locks.values})

end
