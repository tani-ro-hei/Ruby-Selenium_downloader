

@scriptname = $0
@scriptname.sub!( %r!^.*?([^/]+)$! ) { $1 }

def msg(str)
    $stderr.puts "#{@scriptname}: #{str}"
end


require 'selenium-webdriver'
wd = Selenium::WebDriver.for :chrome


html_dir  = './html'
list_file = './list.txt'

least_waitsec = 10
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
