

@scriptname = $0
@scriptname.sub!( %r!^.*?([^/]+)$! ) { $1 }

def msg(str)
    $stderr.puts "#{@scriptname}: #{str}"
end

def eucjp_safe(str)
  # This code is taken from:
  # https://mitsugeek.net/entry/2014/02/24/ruby%E3%81%A7%E6%B3%A2%E3%83%80%E3%83%83%E3%82%B7%E3%83%A5%E3%83%BB%E5%85%A8%E8%A7%92%E3%83%81%E3%83%AB%E3%83%80%E5%95%8F%E9%A1%8C%28utf-8_%E2%86%92_EUC-JP%29
  [
    ["301C", "FF5E"], # wave-dash
    ["2212", "FF0D"], # full-width minus
    ["00A2", "FFE0"], # cent as currency
    ["00A3", "FFE1"], # lb(pound) as currency
    ["00AC", "FFE2"], # not in boolean algebra
    ["2014", "2015"], # hyphen
    ["2016", "2225"], # double vertical lines
  ].inject(str) do |s, (after,  before)|
    s.gsub(
      before.to_i(16).chr('UTF-8'),
      after.to_i(16).chr('UTF-8'))
  end
end


require 'selenium-webdriver'
wd = Selenium::WebDriver.for :chrome

require_relative 'config'
# # #


to_get = []
File.open(list_file, 'r:UTF-8') do |file|
    file.each_line do |line|
        to_get.push line
    end
end
to_get.each { |line| line.chomp! }
to_get.uniq!

already = []
Dir.open(html_dir) do |dir|
    while fn = dir.read
        already.push fn
    end
end
prevsize = to_get.size
to_get = to_get.find_all do |uri|
    already.all? do |fn|
        %r(/#{fn}$) !~ uri
    end
end

idx = prevsize - to_get.size
msg "すでに #{idx} 個のページが取得済みです。#{idx + 1} 個目から要求を開始します。"

to_get.map! do |uri|
    [
        uri,
        uri.sub( %r!^.*?([^/]+)$! ) { "#{html_dir}/#{$1}" }
    ]
end


if defined? login_page then
    wd.get login_page

    wd.find_element(id_input).send_keys id
    wd.find_element(pass_input).send_keys pass
    wd.find_element(submit_button).click
    sleep 5
end

to_get.each do |query|
    uri, outfn = query
    idx += 1

    wd.get uri
    File.open(outfn, 'w:UTF-8') do |file|
        file.write wd.page_source
    end

    sec = Random.rand(least_waitsec.to_f / 2) + least_waitsec
    waitinfo = sprintf('%.2f', sec)
    dateinfo = Time.now.strftime '%m/%d %H:%M:%S'
    msg "[#{dateinfo}] #{idx} 個目: FILE<#{outfn}> に保存しました。#{waitinfo} 秒待機します..."
    sleep sec
end

msg "正常終了！"
gets

=begin

list = []
File.open('./list.txt', 'r:UTF-8') { |file|
    file.each_line { |l|
        list.push l
    }
}
list.each { |l| l.chomp! }
list.uniq!

already = []
Dir.open('./html') { |dir|
    while fn = dir.read
        fn.sub!(/\.html$/, '')
        already.push fn
    end
}
list2 = list.map { |l|
    /(\d+)[^\d]+(\d+)$/ =~ l
    fn = "#{$1}#{$2}"
}
already = already & list2
list2 = list2 - already

idx = already.size
$stderr.puts "#{scriptname}: すでに #{idx} 個のページが取得済みです。#{idx + 1} 個目から要求を開始します。"

list.map! { |l|
    /(\d+)[^\d]+(\d+)$/ =~ l
    fn = "#{$1}#{$2}"

    [l, fn]
}


list.each { |i|
    uri, outfn = i
    unless list2.include?(outfn) then
        next
    end

    outfn = "./html/#{outfn}.html"
    idx += 1

    wd.get uri
    str = eucjp_safe(wd.page_source).encode("eucJP")
    File.open(outfn, 'w:EUC-JP') { |file|
        file.write str
    }

    sec = Random.rand(5.0) + 10
    waitinfo = sprintf('%.2f', sec)
    dateinfo = Time.now.strftime '%m/%d %H:%M:%S'
    $stderr.puts "#{scriptname}: [#{dateinfo}] #{idx} 個目: FILE<#{outfn}> に保存しました。#{waitinfo} 秒待機します..."
    sleep sec
}
wd.quit

=end
