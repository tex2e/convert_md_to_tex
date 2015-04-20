
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
<!--\if 0 コメント \fi-->

# 注意

そのまま出力できるのは1行のみです
複数行のコメントは以下のように指定してください
<!-- \if 0 -->

... 複数行のコメント ...

<!-- \fi -->

markdownと普通の文章の間には必ず空行を入れてください
前後に空行がない場合はmd形式で書いても、普通の文章として扱います

=end

def usage
	puts <<-EOS.gsub(/^\s+\|/, '')
		|usage: ruby #{$PROGRAM_NAME} <markdown_file> [-p]
		|   -p  make pdf file
	EOS
end

md_file_path, option = ARGV
unless md_file_path
	usage
	exit
end

write_file_path = md_file_path.sub(/\.[^.]+$/, '.tex')

# プリアンブルの設定
$preamble = <<EOP
\\documentclass[a4j, titlepage]{jarticle}
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

# <!-- --> の中に書いたテキストはそのままtexとして出力
def convert_keeping_tex_command(latex_str)
	latex_str.gsub!(/% <!--\s*(.+?)\s*-->(?:\n)?/, '\1')
	latex_str
end

# :title -> \title{}
# タイトルの作成
# 1. :title ~ をキャプチャする
# 2. :title ~ を \maketitle に置き換える
# 3. プリアンブル(preamble)にタイトルを追加
def convert_title(latex_str)
	if latex_str.sub!(
		/^
			:title\s+(?<title>.*)\n
			(^:subtitle\s+(?<subtitle>.*)\n)?
			(^:author\s+(?<author>.*)\n)?
			(^:date\s+(?<date>.*)\n)?
		/x,
		"\\maketitle\n\\thispagestyle{empty}\n\\newpage\n\\setcounter{page}{1}\n"
	)
		info = $~ # $LAST_MATCH_INFO
		subtitle = info[:subtitle] ? "\\\\{\\LARGE #{info[:subtitle]}}" : ""

		$preamble << [
			"\\title{ \\Huge #{info[:title]} #{subtitle}}",
			"\\author{ \\Large #{info[:author]} }",
			"\\date{ \\Large #{info[:date]} }",
		].join("\n") + "\n"
	end
	latex_str
end

# code -> screenの書き換え
# :captionなどがないときにはscreenに変換する
def convert_screen(latex_str)
	latex_str.gsub!(
		/^
			(\n[^:][^\n]*\n)
			\n
			\\begin{verbatim}
			(.*?)\n
			\\end{verbatim}
		/mx,
		%w(
			\1
			\begin{screen}
			\begin{verbatim}
			\2
			\end{verbatim}
			\end{screen}
		).join("\n")
	)
	latex_str
end

# code -> itembox + codeの書き換え
def convert_source_code_with_itembox(latex_str)
	latex_str.gsub!(
		/^
			:caption\s+([^:]*)\n?(?::label\s+([^\n]*))?\n
			\n
			\\begin{verbatim}
			(.*?)\n
			\\end{verbatim}
		/mx,
		%w(
			\begin{itembox}[c]{\1}
			\begin{verbatim}
			\3
			\end{verbatim}
			\end{itembox}
		).join("\n")
	)
	puts "In itembox, you cannot set the label \"#{$2}\"" if $2
	latex_str
end

# code -> itembox + code(embed)の書き換え
# [embed](path) が指定されたときに変換を行う
def convert_embed_source_code(latex_str)
	latex_str.gsub!(
		/^
			:caption\s+([^:]*)\n?(?::label\s+([^\n]*))?\n
			\s*\\href{([^}]*)}{embed}
		/mx,
		%w(
			\begin{itembox}[c]{\1}
			{\small
			\verbatiminput{\3}
			}
			\end{itembox}
		).join("\n")
	)
	puts "In itembox, you cannot set the label \"#{$2}\"" if $2
	latex_str
end

# code -> listing + codeの書き換え
# :listing 指定がされたときに変換を行う
def convert_source_code_with_listing(latex_str)
	latex_str.gsub!(
		/^
			:caption\s+([^:]*)\n?(?::label\s+([^\n]*))?\n
			:listing\s*\n
			\n
			\\begin{verbatim}
			(.*?)\n
			\\end{verbatim}
		/mx,
		%w(
			\begin{lstlisting}[caption=\1,label=\2]
			\3
			\end{lstlisting}
		).join("\n")
	)
	latex_str
end

# code -> listing + code(embed)の書き換え
# :listing [embed](path) 指定がされたときに変換を行う
def convert_embed_source_code_with_listing(latex_str)
	latex_str.gsub!(
		/^
			:caption\s+([^:]*)\n?(?::label\s+([^\n]*))?\n
			:listing\s*\\href{([^}]*)}{embed}
		/mx,
		%w(
			\lstinputlisting[caption=\1,label=\2]
			{\3}
		).join("\n")
	)
	latex_str
end

# \section{text}\hypertarget 〜 -> \section
# Kramdownで変換した際に\hypertargetが余分についてくるので、\hypertargetを削除する
def convert_removing_hypertarget(latex_str)
	latex_str.gsub!(/(\\(?:sub)*section{[^}]*})\\hypertarget.*/, '\1')
	latex_str
end

# def -> def + \n
# 定義の後に改行を加える
# 正確には \item[*] の後に \mbox{}\\ を追加する
def convert_adding_newline_to_definition_list(latex_str)
	latex_str.gsub!(/\\item\[[^\]]+\]/, '\0\mbox{}\\\\\\\\')
	latex_str
end

# longtable -> tableの書き換え
# captionとlabelも指定できる
def convert_table(latex_str)
	latex_str.gsub!(
		/
			(?::caption\s+([^:]*)\n?)?(?::label\s+([^\n]*)\n)?\n
			\\begin{longtable}{([^}]+)}
		/x,
		%w(
			\begin{table}[h]
				\centering
				\caption{\1}
				\label{\2}
			\begin{tabular}{\3}
		).join("\n")
	)
	latex_str.gsub!(
		/
			\\end{longtable}
		/x,
		%w(
			\end{tabular}
			\end{table}
		).join("\n")
	)
	latex_str
end

# displaymath -> eqnarray* の書き換え
def convert_eqnarray(latex_str)
	latex_str.gsub!(
		/
			\\begin{displaymath}\n\n
			(.*?)\n
			\\end{displaymath}
		/mx,
		%w(
			\begin{eqnarray*}
			\1
			\end{eqnarray*}
		).join("\n")
	)
	latex_str
end

# figure -> figure
# caption,scale,labelが指定できる
def convert_figure(latex_str)
	latex_str.gsub!(
		/
			\\includegraphics{([^}]*)}\n
			(?::caption\s+([^:]*)\n?)?(?::scale\s+([^:]*)\n?)?(?::label\s+([^\n]*))?
		/x,
		%w(
			\begin{figure}[h]
				\centering
				\includegraphics[scale=\3]{\1}
				\caption{\2}
				\label{\4}
			\end{figure}
		).join("\n")
	)
	latex_str
end

# :cmd{} -> \cmd{}
# バックスラッシュ\から始まるコマンド名に変換する
def convert_command(latex_str)
	latex_str.gsub!(/:(\w+)\\\{(.*?)\\\}/, '\\\\\\1{\2\4}\3')
	latex_str
end

# convert_から始まる関数を実行
self.private_methods.grep(/convert_.*/) do |convert_method|
	latex_str = self.send(convert_method, latex_str)
end

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



__END__

:title Markdown -> Tex [ -> PDF]
:subtitle markdownの記述例
:author TeX2e
:date 2015年4月1日

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

箇条書きには `-,+,*` が使えます。
リストは 1. のように数字とコロンと1つ以上の空白から始めます。

- item1
- item2
	+ nest1
	+ nest2
	+ nest3
		1. item1
		2. item2
		10. item10
		11. item11
- item3
- item4


ソースコードの出力方法

+ ソースコードの前後に1つ以上の空行を置く
+ 4つ以上のインデントまたは1つ以上のタブを置く
+ `:caption` でタイトルを付ける
+ `:label` でラベルを付ける
+ `:listing` で行番号と改ページを行う枠に変更する

出力例

	printf("hello, world");

:caption ソースコード1

	p "hello world"

リスト:ref{sample1}に繰り返し処理の例を示します

:caption 繰り返しの例 :label sample1
:listing

	(1..10).each do |i|
		p i
	end

:caption 埋め込みの例 :label embed1
:listing
	[embed](sample.c)

:caption 埋め込みの例2
	[embed](sample.out)

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

:caption 画像埋め込み例

	![](/path/to/image.eps)
	:caption 題名 :scale 大きさ :label ラベル

ハイフンかアスタリスクを3つ以上並べると水平線が出力されます

---

****




