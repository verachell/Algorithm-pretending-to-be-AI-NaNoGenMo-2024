# Algorithm-pretending-to-be-AI-NaNoGenMo-2024
Creates > 50000 words of fiction algorithmically using a) text file sources and b) keywords that the user types in

## How the algorithm works

This algorithm is a meld of Markov Chaining and the Cut-Up method mashed together in one algorithm. Cut-Up is when a text is segmented and re-arranged to form new text.

Briefly, what happens is that the text is segmented at its most commonly used words. These are defined as the most commonly used words in the text sources used (not necessarily in the English language in general).

Segmentation is done such that each resulting fragment begins and ends with one of the most commonly used words.

So in a brief example, the text `a cat was sitting on a mat and a hamster was running on a wheel and playing`

Now, there's not a ton of words here so let's just assume our most commonly used words are `a`, `on`, `and`, `was`

The fragments would become:
`a cat was` `was sitting on` `on a` `a mat and` `and a` `a hamster was` `was running on` `on a` `a wheel and`

`and playing` is omitted because it doesn't end with a commonly used word

Those fragments then form the basis of a Markov Chain lookup table. Therefore, suppose we randomly start with the fragment `a hamster was`. The next fragment must start with `was`, so the algorithm narrows this down to `was sitting on` and `was running on` - it will pick one of these options randomly, and so on. However, if one of these options contained one of the user keywords, it would pick one of the ones containing the user keyword.

This is a bit different to regular Markov chaining in that the lengths of the fragments in my table will vary. For example, if the original text contains a phrase with several uncommon words in a row, they will wind up all together in 1 fragment, because the text is being cut at the most common words. By contrast, Markov chaining is usually implemented with constant lengths of fragments, typically 2 or 3 words.
