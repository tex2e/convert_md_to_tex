
=begin

これはmarkdown記法のファイルを読み込んで、tex形式に変換したファイルを出力します
以下はmarkdownを略してmdと書きます

# 使用方法

このファイルをrubyで実行します
$ ruby <this_file.rb> <read_file.md> [-p]

<this_file.rb> はこのrubyのソースファイルのパスです
<read_file.md> はmdファイルのパスです
-p オプションは md -> tex だけでなく、tex -> pdf も行います

例:
	$ ruby mdConvertToTex.rb report.md -p
	$ ruby ~/Documents/pgm/ruby/mdConvertToTex.rb ~/Documents/tex/test.md -p

# ソースコード (スペース4つ以上のインデント)
## 枠のみ

	#include <stdio.h>
	int main(){
		printf("Hello world!");
	}


## タイトル付きの枠
:caption タイトル

	#include <stdio.h>
	int main(){
		printf("Hello world!");
	}


## 行番号付きの枠
:caption タイトル :label ラベル
:listing

	#include <stdio.h>
	int main(){
		printf("Hello world!");
	}


## 行番号付きの枠で、ソースコードのファイル場所を指定
:caption タイトル :label ラベル
:listing
	[embed](~/Documents/pgm/c/test.c)


# 箇条書き -+*
+ item1
+ item2
+ item3

# 表の作成
:caption 説明 :label ラベル

alpha | beta
------|-----
100   | 200
120   | 240

# 数式  
$$ x = \frac{1}{2} $$

# 画像の埋め込み
![画像タイトル(省略可能)](画像のpath)
:caption 説明 :scale 0.6 :label ラベル

# そのまま出力
<!-- mdに書いたtexの命令をtexのままにしたいときなどにお使いください -->

# コメント
<!--\if 0 コメント \fi-->

=end


# gem install kramdown
require 'kramdown'

read_file_path, option = ARGV[0], ARGV[1]
raise 'no argument' if read_file_path.nil?
raise 'argument[0] is not a markdown file as ".md"' unless read_file_path.match(/\.md$/)
write_file_path = read_file_path.sub(/\.md$/, '.tex')

# プリアンブルの設定
preamble = <<"EOS"
\\documentclass[a4j]{jarticle}
\\usepackage{amsmath,amssymb} % 数式
\\usepackage{fancybox,ascmac} % 丸枠
\\usepackage[dvipdfmx]{graphicx} % 図
% プログラムリストで使用
\\usepackage{ascmac}
\\usepackage{here}
\\usepackage{txfonts}
\\usepackage{listings, jlisting} % プログラムリスト
\\renewcommand{\\lstlistingname}{リスト}
\\lstset{
  language=c,
  basicstyle=\\ttfamily\\normalsize, % コードのフォントと文字サイズ
  commentstyle=\\textit, % コメント部分のフォント
  classoffset=1,
  keywordstyle=\\bfseries,
  frame=tRBl,
  framesep=5pt,
  showstringspaces=false,
  numbers=left,
  stepnumber=1,
  numberstyle=\\footnotesize,
  tabsize=3 % インデントの深さ（スペースの数）
}
EOS

# mdファイルを読み込んで、texの文字列に変換する
md_str = File.open(read_file_path).read
latex_str = Kramdown::Document.new(md_str).to_latex

# <!-- --> の中に書いたテキストはそのままtexとして出力
latex_str.gsub!(/% <!--\s*(.+?)\s*-->(?:\n)?/, '\1')

# code -> itembox + codeの書き換え
latex_str.gsub!(/^
	:caption\s+([^:]*)(?::label\s+([^\n]*))?\n
	\n
	\\begin{verbatim}
	(.*?)
	\\end{verbatim}
	/mx, 
	'\begin{itembox}[c]{\1}\begin{verbatim}'+"\n"+
	'\3\end{verbatim}\end{itembox}'
)

# code -> listing + codeの書き換え
# :listing 指定がされたときに変換を行う
latex_str.gsub!(/^
	:caption\s+([^:]*)(?::label\s+([^\n]*))?\n
	:listing\s*\n
	\n
	\\begin{verbatim}
	(.*?)
	\\end{verbatim}
	/mx, 
	'\begin{lstlisting}[caption=\1,label=\2]'+"\n"+
	'\3\end{lstlisting}'
)

# code -> listing + code(embed)の書き換え
# :listing [embed](path) 指定がされたときに変換を行う
latex_str.gsub!(/^
	:caption\s+([^:]*)(?::label\s+([^\n]*))?\n
	:listing\s*\\href{([^}]*)}{embed}
	/mx, 
	'\lstinputlisting[caption=\1,label=\2]'+"\n"+
	'{\3}'
)

# code -> screenの書き換え
# 上記3つのcode変換が発生しなかったときにはscreenに変換する
latex_str.gsub!(/^
	\n
	\\begin{verbatim}
	(.*?)
	\\end{verbatim}
	/mx, 
	'\begin{screen}\begin{verbatim}'+"\n"+
	'\1'+
	'\end{verbatim}\end{screen}'
)

# \section{text}\hypertarget 〜 -> \section
# Kramdownで変換した際に\hypertargetが余分についてくるので、\hypertargetを削除する
latex_str.gsub!(/(\\(?:sub)*section{[^}]*})\\hypertarget.*/, '\1')

# longtable -> tableの書き換え
# captionとlabelも指定できる
latex_str.gsub!(/
	(?::caption\s+([^:]*)\n?)?(?::label\s+([^\n]*)\n)?\n
	\\begin{longtable}{([^}]+)}
	/x, [
	'\begin{table}[h]',
		'\centering',
		'\caption{\1}',
		'\label{\2}',
	'\begin{tabular}{\3}',
	].join("\n")
)
latex_str.gsub!(/
	\\end{longtable}
	/x, [
	'\end{tabular}',
	'\end{table}',
	].join("\n")
)

# displaymath -> eqnarray* の書き換え
latex_str.gsub!(/\\begin{displaymath}\n\n/, 
	"\\begin{eqnarray*}\n")
latex_str.gsub!(/\\end{displaymath}\n/, 
	"\\end{eqnarray*}\n")

# figure -> figure
# scaleとlabelも指定できる
latex_str.gsub!(/
	\\includegraphics{([^}]*)}\n
	(?::caption\s+([^:]*)\n?)?(?::scale\s+([^:]*)\n?)?(?::label\s+([^\n]*))?\n
	/x, [
	'\begin{figure}[h]', 
		'\centering', 
		'\includegraphics[scale=\3]{\1}', 
		'\caption{\2}', 
		'\label{\4}', 
	'\end{figure}',
	].join("\n") + "\n"
)

# :title -> \title{}
# タイトルの作成
# 1. :title ~ をキャプチャする
# 2. :title ~ を \maketitle に置き換える
# 3. プリアンブル(preamble)にタイトルを追加
if latex_str.sub!(/
	^:title\s+(?<title>.*)\n
	(^:subtitle\s+(?<subtitle>.*)\n)?
	(^:author\s+(?<author>.*)\n)?
	(^:date\s+(?<date>.*)\n)?
	/x, 
	"\\maketitle\n\\thispagestyle{empty}\n\\newpage\n\\setcounter{page}{1}\n"
	)
then
	preamble << "\\title{{　}\\\\{　}\\\\{\\Huge #{$~[:title]}}\n"
	preamble << "\\\\{\\LARGE #{$~[:subtitle]}}\n" if $~[:subtitle]
	preamble << "\\\\{　}" * 17 + "}\n"
	preamble << "\\author{\\Large #{$~[:author]}}\n\\date{\\Large #{$~[:date]}}\n"
end

# :cmd{} -> \cmd{}
# バックスラッシュ\から始まるコマンド名
latex_str.gsub!(/:(\w+)\\\{(.*?)\\\}/, 
	'\\\\\\1{\2\4}\3')

# texファイルに書き込み
File.open(write_file_path, "w") do |f|
	tex_str = "#{preamble}\n\\begin{document}\n#{latex_str}\\end{document}"
	f.write tex_str
end

# -pオプションでpdfに変換する
if option == "-p"
	puts ">> every porcess was excused in #{`pwd`}"

	# mdファイルが置いてあるディレクトリ
	workspace_dir = write_file_path.match(%r{^[/~]?(?:[^/]+/)*})[0]
	tex_file_path = write_file_path
	dvi_file_path = write_file_path.sub(/.tex$/, '.dvi')
	tex_file_name = tex_file_path.match(%r{[^/]+\.tex$})[0]
	dvi_file_name = dvi_file_path.match(%r{[^/]+\.dvi$})[0]
	file_name = dvi_file_name.sub(/\.dvi/, "")

	puts "#{tex_file_name} -> #{dvi_file_name}"

	# platexによるコンパイルを行う
	# コンパイルエラーのときにplatexのプロセスがsleepしてしまうので、threadとして行う
	platex_result = ""
	thread = Thread.new do 
		puts ">> tex compile 1 time"
		platex_result = `platex --kanji=utf8 #{tex_file_path}`
	end

	# 3秒待ってもコンパイルが終わらないときはコンパイルエラーが発生したと考えて、threadを終了する
	unless thread.join(3)
		puts ">> some thing is wrong with \"#{tex_file_path}\""
		puts ">> please put this command for check the error"
		print "\nplatex --kanji=utf8 #{tex_file_path}\n\n"
		exit
	end
	
	# コンパイルした際に「LaTeX Warning: label(s) may have changed.」が表示されたときは、再コンパイル
	n = 1
	while platex_result.match(
		/\n\nLaTeX Warning: Label\(s\) may have changed\. Rerun to get cross-references right\./)
		puts ">> tex compile #{n += 1} time"
		platex_result = `platex --kanji=utf8 #{tex_file_path}`
	end
	
	# platexによって生成されるdviファイルなどはカレントディレクトリに保存される
	# dviファイルをpdfファイルに変換する
	`dvipdfmx -d 5 #{dvi_file_name}`
	
	# カレントディレクトリにある生成されたファイル(dviやpdfなど)をmdファイルのあるディレクトリに移動させる
	file_types = %w(aux dvi log pdf)
	file_types.each do |type|
		`mv #{file_name}.#{type} #{workspace_dir}`
	end
	
end

__END__

はじめに
=======

これはMarkdownファイルをtexファイルに変換するためのプログラムです

#見出し1

##見出し2

###見出し3

##変換できること

+ 箇条書き
+ ソースコード（枠で囲むなど）
+ 表
+ 数式
+ 画像の埋め込み

##使用例

箇条書きには -,+,* が使えます。
リストは 1. のように数字とコロンと1つ以上の空白から始めます。

- item1
- item2
- item3
	+ nest1
	+ nest2
	+ nest3
- item4
- item5

1. item1
2. item2
3. item3
10. item10
11. item11

ソースコードの出力方法

+ ソースコードの前後に1つ以上の空行を置く
+ 4つ以上のインデントまたは1つ以上のタブを置く
+ `:caption` でタイトルを付ける
+ `:label` でラベルを付ける
+ `:listing` で行番号と改ページを行う枠に変更する

:caption ソースコード1

	p "hello world"

リスト:ref{sample1}に繰り返し処理の例を示します

:caption 繰り返しの例 :label sample1
:listing

	(1..10).each do |i|
		p i
	end


:caption 表の説明 :label table:1

 Left align | Right align | Center align 
:-----------|------------:|:------------:
 This       | This        | This         
 column     | column      | column       
 will       | will        | will         
 be         | be          | be           
 left       | right       | center       
 aligned    | aligned     | aligned      


数式は$$で囲みます

$$
\frac{\pi}{2}
= \left( \int_{0}^{\infty} \frac{\sin x}{\sqrt{x}} dx \right)^2 
= \sum_{k=0}^{\infty} \frac{(2k)!}{2^{2k}(k!)^2} \frac{1}{2k+1} 
= \prod_{k=1}^{\infty} \frac{4k^2}{4k^2 - 1}
$$


画像を埋め込む際は `![]()` を使います

![角括弧内の文章は出力されません](/path/to/test.ps)
:caption 画像の説明 :scale 0.6 :label fig:sample1


ハイフンかアスタリスクを3つ以上並べると水平線が出力されます

---

****

