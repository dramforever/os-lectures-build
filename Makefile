SOURCE = $(filter-out slide-template.tex,$(wildcard *.tex))
PDF = $(patsubst %.tex,%.pdf,$(SOURCE))
NAME = $(notdir $(CURDIR))

$(NAME).pdf: $(sort $(PDF))
	pdftk $^ cat output $@

%.pdf: %.tex
	latexmk -pdf -pdflatex='xelatex %O %S' $<

.PHONY: all clean cleanall
all: $(NAME).pdf $(PDF)

cleanall:
	rm -f *.pdf *.out *.toc *.aux *.log *.nav *.gz *.snm *.vrb *.bak *.org ~*

clean:
	rm -f *.out *.toc *.aux *.log *.nav *.gz *.snm *.vrb
