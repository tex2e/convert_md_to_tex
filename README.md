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

## ソースコード (スペース4つ以上のインデント)
### 枠のみ

	#include <stdio.h>
	int main(){
		printf("Hello world!");
	}

### タイトル付きの枠
:caption タイトル

	#include <stdio.h>
	int main(){
		printf("Hello world!");
	}

### タイトル付きの枠で、ソースコードのファイル場所を指定
:caption タイトル
	[embed](/path/to/source)

### 行番号付きの枠
:caption タイトル :label ラベル
:listing

	#include <stdio.h>
	int main(){
		printf("Hello world!");
	}

### 行番号付きの枠で、ソースコードのファイル場所を指定
:caption タイトル :label ラベル
:listing
	[embed](/path/to/source)

## 箇条書き -+*
+ item1
+ item2
+ item3

## 定義 :
def1
: description1

def2
: description2

## 表の作成
:caption 説明 :label ラベル

alpha | beta
------|-----
100   | 200
120   | 240

## 数式
$$ x = \frac{1}{2} $$

## 画像の埋め込み
![](画像のpath)
:caption 説明 :scale 0.6 :label ラベル

## そのまま出力
<!-- mdに書いたtexの命令をtexの命令として実行したいときなどにお使いください -->

<!--\if 0 コメント \fi-->

### 注意

そのまま出力できるのは1行のみです
複数行のコメントは以下のように指定してください
<!-- \if 0 -->

... 複数行のコメント ...

<!-- \fi -->

markdownと普通の文章の間には必ず空行を入れてください
前後に空行がない場合はmd形式で書いても、普通の文章として扱います

