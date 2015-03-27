

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

text

	printf("hello, world");

:text

	printf("hello, world");

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

![角括弧内の文章は出力されません]()
<!--\if 0 :caption 画像の説明 :scale 0.6 :label fig:sample1 \fi-->


ハイフンかアスタリスクを3つ以上並べると水平線が出力されます

---

****

