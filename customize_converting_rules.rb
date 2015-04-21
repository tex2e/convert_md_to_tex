#
# kramdownの変換で、気に入らない点を正規表現で置き換える
#
module CustomizeConvertingRules
	module_function

	# convert_から始まる全ての関数を実行
	def converts(latex_str)
		self.methods.grep(/convert_.*/) do |convert_method|
			latex_str = self.send(convert_method, latex_str)
		end
		latex_str
	end

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
				"\\title{ \\Huge #{info[:title]} #{subtitle} }",
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
		latex_str.gsub!(/:ref\\\{(.*?)\\\}/, '\\\\ref{\1}')
		latex_str
	end
end


