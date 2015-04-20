# mdConvertToTex

これはmarkdown(md)記法のファイルを読み込んで、tex形式に変換したファイルを出力します

# 使い方

このファイルをrubyで実行します
$ ruby <this_file> <markdown_file> [-p]

<this_file> はこのrubyのソースファイルのパスです
<markdown_file> はmdファイルのパスです
このコマンドは md -> tex を行います。
-p オプションで追加の変換 tex -> pdf も行います

例:
	$ ruby mdConvertToTex.rb report.md -p
	
# 使用例

:title Markdown -> TeX [ -> PDF ]
:subtitle markdownの記述例
:author @TeX2e
:date 2015/4/1

Overview
=======

これはMarkdownファイルをTeXファイルに変換するためのrubyスクリプトです。
rubyが実行できる環境と、gemの"kramdown"が必要です。

# Usage

	ruby <this_script> <md_file> [-p]

# Structural Elements

+ Headers
+ Lists
+ Code Blocks
+ Tables
+ Math Blocks
+ Images

# Markdown Syntax

## Headers

見出しは `#` を使って表します。

:caption 見出しの例

	# First level header

	## Second level header

	### Third level header

## (Un)Ordered Lists

箇条書きには `-,+,*` が使えます。
リストは `1.` のように数字とコロンと1つ以上の空白をリストの先頭に付けます。

	- item1
	- item2
	- item3

	1. item1
	2. item2
	3. item3


## Definition Lists

定義の次の行に `:` があれば、定義とその説明を書くことができます。

	def1
	: description

	def2
	: description

## Code Blocks

ソースコードを出力する方法

+ ソースコードの前後に1つ以上の空行を置く
+ 4つ以上のインデントまたは1つ以上のタブを置く
+ `:caption` でタイトルを付ける
+ `:label` でラベルを付ける
+ `:listing` で行番号と改ページを行う枠に変更する

ソースコードは、丸枠で囲むか、行番号付きの枠で囲むかの2通りの選択肢があります。

丸枠を使う方法は3通りあります。

	:caption タイトルなしの枠
	
		　
		    printf("hello, world");
		　
	
	:caption 丸枠の例
	
		:caption <caption>
	
		    printf("hello, world");
		　
	
	:caption 埋め込みの例
	
		:caption <caption>
		    [embed](/path/to/source.c)
	　

行番号付きの枠を使う方法は2通りあります。

	:caption 行番号付きの枠
	
		:caption <caption> :label <label>
		:listing
	
		    (1..10).each do |i|
		        p i
		    end
	　

	:caption 埋め込みの例
	
		:caption <caption> :label <label>
		:listing
		    [embed](/path/to/source.c)
	　

行番号付きの枠の場合、`:``ref{<label>}` で参照を行うことができます。


## Tables

表は、仕切りに `-` と `|` を使って表します

	:caption table example

	:caption <caption> :label <label>
	
	 colum1     | colum2      | colum3
	:-----------|------------:|:------------:
	 This       | This        | This         
	 column     | column      | column       
	 will       | will        | will         
	 be         | be          | be           
	 left       | right       | center       
	 aligned    | aligned     | aligned   

	table:ref{table:1} shows ...

## Math Blocks

数式は$$で囲みます

	解の公式は $$ x = \frac{-b\pm\sqrt{b^2-4ac}}{2a} $$ で表せます。

	$$
	\frac{\pi}{2}
	= \left( \int_{0}^{\infty} \frac{\sin x}{\sqrt{x}} dx \right)^2 
	= \sum_{k=0}^{\infty} \frac{(2k)!}{2^{2k}(k!)^2} \frac{1}{2k+1} 
	= \prod_{k=1}^{\infty} \frac{4k^2}{4k^2 - 1}
	$$

## Images

画像を埋め込む際は `![]()` を使います

	![](/path/to/image.eps)
	:caption <caption> :scale <scale> :label <label>

## Horizontal Rules

ハイフンかアスタリスクを3つ以上並べると水平線が出力されます

	---

	****



