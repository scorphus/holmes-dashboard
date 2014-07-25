require 'nokogiri'
require 'open-uri'

grapher_url = 'http://datacenter.globoi.com/grapher.cgi?target=%2Fservers%2Flinux%2Friomp97lb03%2Fnet%2Feth2;ranges=d;view=Octets'

bits_in_out = []
x_index = 0

SCHEDULER.every '5m', first_in: 0, allow_overlapping: false do
    grapher = Nokogiri::HTML(open(grapher_url))
    tds = grapher.xpath('.//td[contains(.,"Average bits out")]')

    bits_in = tds[0].content.match(/cur: ([0-9]+)/i)[1].to_i
    bits_out = tds[1].content.match(/cur: ([0-9]+)/i)[1].to_i

    if bits_in_out.count > 24 * 12 # keep last 24 hours
        bits_in_out.shift
    end

    x_index += 1
    bits_in_out << {x: x_index, y: bits_in + bits_out}

    send_event('bits_in_out', points: bits_in_out)
end
