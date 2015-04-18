
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

