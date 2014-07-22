require 'nokogiri'
require 'open-uri'

grapher_url = 'http://datacenter.globoi.com/grapher.cgi?target=%2Fservers%2Flinux%2Friomp97lb03%2Fnet%2Feth2;ranges=d;view=Octets'

bits_out = []
x_index = 0

SCHEDULER.every '5m' do
    grapher = Nokogiri::HTML(open(grapher_url))
    tds = grapher.xpath('.//td[contains(.,"Average bits out")]')
    bit_out = tds[1].content.match(/cur: ([0-9]*)/i)[1].to_i

    if bits_out.count > 24 * 12 # keep last 24 hours
        bits_out.shift
    end

    x_index += 1
    bits_out << {x: x_index, y: bit_out}

    send_event('bits_out', points: bits_out)
end
