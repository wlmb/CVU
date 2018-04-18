# Ejemplo: 
# make bibliografia_pineda.xml
%.xml :: %.bib
	 bib2xml $< > $@

# Ejemplo: 
# make bibliografia_pineda.yaml
%.yaml :: %.bib
	pandoc-citeproc $< -y > $@

# En la pagina 63 del manual de pandoc https://pandoc.org/MANUAL.pdf parece que esta la informacion relevante. 
#
#
# bibliografia_pineda.bib
