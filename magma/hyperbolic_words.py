# This script augments creates the magma file small_hyperbolic.magma out of
# the file small_hyperbolic.magma_template by filling in the lines
# "hyp_words_a := ..." and "hyp_words_c := ..." with lists of all short words
# representing short hyperbolic elements.

from itertools import permutations,product
import sys
basic_words_a = ['abcb','abcabc','abcbabcb','abcabcabcb','abcbabcbabcb','abcabcabcabc']#,'abcabcabcbabcb']
basic_words_c = ['acbc','cbca','acabcb','cabcba','acbcacbc','cbcacbca','acabcabcbc','cabcabcbca','acabcbacabcb','cabcbacabcba','acbcacbcacbc','cbcacbcacbca']

def words(basic_word):
    for p in permutations('ab'):
        d = dict(zip('abc',p + ('c',)))
        subs_word = ''.join(d[i] for i in basic_word)
        for exps in product(('','^-1'), repeat=len(subs_word)):
            word = ' * '.join((c + e) for (c,e) in zip(subs_word,exps))
            yield word

with open("small_hyperbolic.magma_template","r") as magma_template:
  with open("small_hyperbolic.magma","w") as magma:
    for line in magma_template:
      if 'hyp_words_a := ' in line:
        magma.write('hyp_words_a := [ %s ];\n' % ' , '.join('{ %s }' % ', '.join(words(basic_word)) for basic_word in basic_words_a))
      elif 'hyp_words_c := ' in line:
        magma.write('hyp_words_c := [ %s ];\n' % ' , '.join('{ %s }' % ', '.join(words(basic_word)) for basic_word in basic_words_c))
      else:
        magma.write(line)
