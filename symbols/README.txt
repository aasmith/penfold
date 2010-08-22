When building symbol files, it can be useful to ensure that symbols from a given set of
files do not occur in more than one file. To print duplicates:

 sort -o tmpA symbolsA.txt
 sort -o tmpB symbolsB.txt
 comm -12 tmpA tmpB

