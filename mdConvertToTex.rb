
=begin

これはmarkdown(md)記法のファイルを読み込んで、tex形式に変換したファイルを出力します

# 使用方法

このファイルをrubyで実行します
$ ruby <this_file> <markdown_file> [-p]

<this_file> はこのrubyのソースファイルのパスです
<markdown_file> はmdファイルのパスです
このコマンドは md -> tex を行います。
-p オプションで追加の変換 tex -> pdf も行います

例:
	$ ruby mdConvertToTex.rb report.md -p

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

## タイトル付きの枠で、ソースコードのファイル場所を指定
:caption タイトル
	[embed](/path/to/source)

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
	[embed](/path/to/source)

# 箇条書き -+*
+ item1
+ item2
+ item3

# 定義 :
def1
: description1

def2
: description2

# 表の作成
:caption 説明 :label ラベル

alpha | beta
------|-----
100   | 200
120   | 240

# 数式
$$ x = \frac{1}{2} $$

# 画像の埋め込み
![](画像のpath)
:caption 説明 :scale 0.6 :label ラベル

# そのまま出力
<!-- mdに書いたtexの命令をtexの命令として実行したいときなどにお使いください -->

# コメント
{::comment}
comment lines ...
{:/comment}

markdownと普通の文章の間には必ず空行を入れてください
前後に空行がない場合はmd形式で書いても、普通の文章として扱います

=end

def usage
	puts <<-EOS.gsub(/^\s+\|/, '')
		|usage: ruby #{$PROGRAM_NAME} <markdown_file> [-p]
		|
		| -p  make pdf file
	EOS
	exit
end

md_file_path, option = ARGV
usage unless md_file_path

write_file_path = md_file_path.sub(/\.[^.]+$/, '.tex')

# プリアンブルの設定
$preamble = <<EOP
\\documentclass[a4j, titlepage]{jarticle}
\\usepackage[utf8]{inputenc}
\\usepackage{amsmath,amssymb} % 数式
\\usepackage{fancybox,ascmac} % 丸枠
\\usepackage[dvipdfmx]{graphicx} % 図
\\usepackage{verbatim} % ソースコードの埋め込み
% プログラムリストで使用
\\usepackage{ascmac}
\\usepackage{here}
\\usepackage{txfonts}
\\usepackage{listings, jlisting} % プログラムリスト
\\renewcommand{\\lstlistingname}{リスト}
\\lstset{
  language=c,
  basicstyle=\\ttfamily\\small, % コードのフォントと文字サイズ
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
EOP

# mdファイルを読み込んで、texの文字列に変換する
require 'kramdown'
md_str = File.open(md_file_path, &:read)
latex_str = Kramdown::Document.new(md_str).to_latex

require "#{File.dirname(__FILE__)}/customize_converting_rules.rb"
latex_str = CustomizeConvertingRules.converts(latex_str)

# texファイルに書き込み
File.open(write_file_path, 'w') do |f|
	tex_str = "#{$preamble}\n\\begin{document}\n#{latex_str}\\end{document}"
	f.write tex_str
end

# ---------------------------------------------------------------------
# -pオプションでpdfに変換する（-pが無ければ終了）
if option == '-p'
	# mdファイルが置いてあるディレクトリを変数として保存
	match = write_file_path.match(%r{^([/~]?(?:[^/]+/)*)([-\w\.]+?)\.tex})
	workspace_dir = match[1]
	file_name     = match[2]
	tex_file_path = workspace_dir + file_name + '.tex'
	# dvi_file_path = workspace_dir + file_name + '.dvi'
	tex_file_name = file_name + '.tex'
	dvi_file_name = file_name + '.dvi'

	puts "#{tex_file_name} -> #{dvi_file_name}"

	n = 1
	print_compile_time = -> n { ">> tex compile #{n} time" }

	# platexによるコンパイルを行う
	puts print_compile_time.call(n)
	platex_result = %x(yes x | platex --kanji=utf8 #{tex_file_path})

	# コンパイルが失敗したら、エラーの内容を出力して終了
	if platex_result.match(/^\?/)
		puts platex_result#.sub(/(?:[^\n]+|\n[^\n])+\n/, '').gsub(/^\(.*\n/, '')
		exit
	end

	# コンパイルした際に「LaTeX Warning: label(s) may have changed.」が表示されたときは、再コンパイル
	while platex_result.match(
		"\n\nLaTeX Warning: Label(s) may have changed. Rerun to get cross-references right.")
		puts print_compile_time.call(n += 1)
		platex_result = %x(platex --kanji=utf8 #{tex_file_path})
	end

	# platexによって生成されるdviファイルなどはカレントディレクトリに保存される
	# dviファイルをpdfファイルに変換する
	puts %x(dvipdfmx -d 5 #{dvi_file_name})

	# カレントディレクトリにある生成されたファイル(dviやpdfなど)をmdファイルのあるディレクトリに移動させる
	unless workspace_dir.empty?
		file_types = %w(aux dvi log pdf)
		file_types.each do |type|
			%x(mv #{file_name}.#{type} #{workspace_dir})
		end
	end
end




