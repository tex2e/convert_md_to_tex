
:title Markdown -> TeX [ -> PDF ]
:subtitle How to write extended markdown and convert to TeX
:author @TeX2e
:date 2015/4/1

{::comment}
実装予定
:preamble do - end で、preambleに追加する項目を設定する

:preamble do
	`\def\lstlistingname{List}`
	`\def\tablename{Table}`
:end
{:/comment}

Overview
=======

これはMarkdownファイルをTeXファイルに変換するためのrubyスクリプトです。

# Requirements

You need to install gem ``kramdown"

	$ gem install kramdown

Or add this line to your Gemfile:

	gem 'kramdown'

then enter `bundle` command to install ``kramdown"

# Usage

enter the following commands:

	$ ruby <this_script> [-optsions] <md_file>

`<this_script>`
: mdをtexに変換するスクリプトのファイル名

`<md_file>`
: 変換元となるmarkdownファイル

`-options`
: optionには次のものがあります

  `-p`
  : texに変換した後、pdfに変換するオプション

  `--pdf`
  : 同上

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

:caption headers example

	# First level header

	## Second level header

	### Third level header

## (Un)Ordered Lists

箇条書きには `-,+,*` が使えます。
リストは `1.` のように数字とコロンと1つ以上の空白をリストの先頭に付けます。

:caption list example

	- item1
	- item2
	- item3

    1. item1
    2. item2
    3. item3

Output:

- item1
- item2
	+ nest1
	+ nest2
		* deep nest1
		* deep nest2
- item3
- item4

----

1. item1
2. item2
	1. nest1
	2. nest2
		1. deep nest1
		2. deep nest2
3. item3
4. item4

## Definition Lists

定義の次の行に `:` があれば、定義とその説明を書くことができます。

:caption definition list example

	def1
	: description

	def2
	: description

Output:

Laziness
: The quality that makes you go to great effort to reduce overall energy expenditure. It makes you write labor-saving programs that other people will find useful, and document what you wrote so you don't have to answer so many questions about it. Hence, the first great virtue of a programmer.

Impatience
: The anger you feel when the computer is being lazy. This makes you write programs that don't just react to your needs, but actually anticipate them. Or at least that pretend to. Hence, the second great virtue of a programmer.

Hubris
: Excessive pride, the sort of thing Zeus zaps you for. Also the quality that makes you write (and maintain) programs that other people won't want to say bad things about. Hence, the third great virtue of a programmer.

## Code Blocks

ソースコードを出力する方法

+ ソースコードの前後に1つ以上の空行を置く
+ 4つ以上のインデントまたは1つ以上のタブを置く
+ `:caption` でタイトルを付ける
+ `:label` でラベルを付ける
+ `:listing` で行番号と改ページを行う枠に変更する

ソースコードは、丸枠で囲むか、行番号付きの枠で囲むかの2通りの選択肢があります。

コードを説明なしの丸枠で囲む場合は、前後に何も書きません。

:caption without caption

	　
	    printf("hello, world");
	　

Output:

	printf("hello, world");

----

コードを丸枠で囲む場合は、コードから2行上に `:caption` から始まる行を書きます。

:caption 丸枠の例

	:caption <caption>

	    printf("hello, world");
	　

Output:

:caption hello, world

	printf("hello, world");

----

丸枠に外部ファイルのコードを埋め込む場合は、`:caption` の次の行に、`[embed](<path>)` を書きます。

:caption example to embed code

	:caption <caption>
	    [embed](/path/to/source.c)
	　

Output:

:caption embed test
	[embed](./sample.c)

----

行番号付きの枠（リスト）を使う方法は2通りあります。

コードをリストにする場合は、コードから3行上に `:caption` と `:label`を書き、2行上に `:listing` を書きます。

:caption 行番号付きの枠

	:caption <caption> :label <label>
	:listing

	    (1..10).each do |i|
	        p i
	    end
	　
	
Output:
　
:caption iterate :label list:1
:listing

	(1..10).each do |i|
		p i
	end

----

リストに外部ファイルのコードを埋め込む場合は、`:listing` の次の行に、`[embed](<path>)` を書きます。

:caption example to embed code in listing

	:caption <caption> :label <label>
	:listing
	    [embed](/path/to/source.c)
	　

Output:

:caption embed in listing :label list:2
:listing
	[embed](./sample.c)

----

リストの場合、`:``ref{<label>}` で参照を行うことができます。

List :ref{list:2} shows ...

## Tables

To display table, we use pipe `|` and minus `-`

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

:caption table sample :label table:1

 Left align | Right align | Center align 
:-----------|------------:|:------------:
 This       | This        | This         
 column     | column      | column       
 will       | will        | will         
 be         | be          | be           
 left       | right       | center       
 aligned    | aligned     | aligned      


表の場合、`:``ref{<label>}` で参照を行うことができます。

Table :ref{table:1} shows ...

## Math Blocks

数式は$$で囲みます

:caption equation example

	$$ inline math block $$

	$$
	multiline math block
	$$


Output:

解の公式は $$ x = \frac{-b\pm\sqrt{b^2-4ac}}{2a} $$ で表せます。
式 $$ \sum_{n = 1}^{\infty} \frac{1}{n} $$ の収束値を求めます。

$$
\frac{\pi}{2}
= \left( \int_{0}^{\infty} \frac{\sin x}{\sqrt{x}} dx \right)^2 
= \sum_{k=0}^{\infty} \frac{(2k)!}{2^{2k}(k!)^2} \frac{1}{2k+1} 
= \prod_{k=1}^{\infty} \frac{4k^2}{4k^2 - 1}
$$

## Images

画像を埋め込む際は `![]()` を使います

:caption example of displaying an image

	![](/path/to/image.eps)
	:caption <caption> :scale <scale> :label <label>

## Horizontal Rules

ハイフンかアスタリスクを4つ以上並べると水平線が出力されます

:caption horizontal rules example

	----

	****

Output:

----

****

## Blockquotes

:caption blockquotes example

	> This is a blockquote
	> on multiple line
	> but it looks one line

Output:

This is para text.

> This is a blockquote
> on multiple line.
> but it looks like one line

List work in blockquotes

> This is a blockquote
>
> * list work
> * item1
> * item2
>

## Footnotes

This is some text.[^1]. Other text.[^footnote].

[^1]: This is *italic* footnote.

[^footnote]:
	You can use blockquotes.

	> Blockquotes can be in a footnote.

## Comments

{::comment}
This text is completely ignored by kramdown - a comment in the text.
{:/comment}

## Alias

:alias alias test = hoge fuga piyo

(alias test)


