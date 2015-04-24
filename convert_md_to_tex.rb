
def usage
	puts <<-EOS.gsub(/^\s+\|/, '')
		|Usage: ruby #{$PROGRAM_NAME} <options> <markdown_file>
		|    -p         make pdf file
		|    --pdf      make pdf file
		|    --sample   create sample markdown file
	EOS
	exit
end

# get options
require 'optparse'
file_path = ARGV.last
option = ARGV.getopts('p', 'pdf', 'sample')

if option['sample']
	puts File.open(File.dirname(__FILE__) + '/sample.md', &:read)
	exit
end

usage if file_path.nil? || File.exist?(file_path) == false

# store the file path and name
class FileInfo
	attr_reader :path, :name

	def initialize
		@path = {}
		@name = {}
	end

	def set(dir, file, extension)
		@path[extension.to_sym] = "#{dir}/#{file}.#{extension}"
		@name[extension.to_sym] = "#{file}.#{extension}"
	end
end

file = File.basename(file_path, '.*')
dir = File.dirname(file_path)
files = FileInfo.new

files.set(dir, file, 'md')
files.set(dir, file, 'tex')

# set the preamble in latex
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

# convert from md to latex
require 'kramdown'
md_str = File.open(files.path[:md], &:read)
latex_str = Kramdown::Document.new(md_str).to_latex

require File.dirname(__FILE__) + '/customize_converting_rules.rb'
latex_str = CustomizeConvertingRules.converts(latex_str)

# texファイルに書き込み
File.open(files.path[:tex], 'w') do |f|
	puts "#{files.name[:md]} -> #{files.name[:tex]}"
	tex_str = "#{$preamble}\n\\begin{document}\n#{latex_str}\\end{document}"
	f.write tex_str
end

# ---------------------------------------------------------------------
# -pオプションでpdfに変換する（-pが無ければ終了）
if option['p'] || option['pdf']
	files.set(dir, file, 'dvi')
	puts "#{files.name[:tex]} -> #{files.name[:dvi]}"

	n = 1
	compile_times = -> n { ">> tex compile #{n} times" }

	# platexによるコンパイルを行う
	puts compile_times.call(n)
	platex_result = %x(yes x | platex --kanji=utf8 #{files.path[:tex]})

	# コンパイルが失敗したら、エラーの内容を出力して終了
	if platex_result.match(/^\?/)
		puts platex_result
		exit
	end

	# コンパイルした際に「LaTeX Warning: label(s) may have changed.」が表示されたときは、再コンパイル
	while platex_result.match(
		/^LaTeX Warning: Label\(s\) may have changed. Rerun to get cross-references right\./)
		puts compile_times.call(n += 1)
		platex_result = %x(platex --kanji=utf8 #{files.path[:tex]})
	end

	# platexによって生成されるdviファイルなどはカレントディレクトリに保存される
	# dviファイルをpdfファイルに変換する
	puts %x(dvipdfmx -d 5 #{files.name[:dvi]})

	# カレントディレクトリにある生成されたファイル(dviやpdfなど)をmdファイルのあるディレクトリに移動させる
	unless dir == '.'
		file_types = %w(aux dvi log pdf)
		file_types.each do |type|
			%x(mv #{file}.#{type} #{dir})
		end
	end
end

=begin

これはmarkdown(md)記法のファイルを読み込んで、tex形式に変換したファイルを出力します

# 使用方法

このファイルをrubyで実行します
$ ruby <this_file> [-p] <markdown_file>

<this_file> はこのrubyのソースファイルのパスです
<markdown_file> はmdファイルのパスです
このコマンドは md -> tex を行います。
-p オプションで追加の変換 tex -> pdf も行います

例:
	$ ruby convert_md_to_tex.rb -p report.md

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



