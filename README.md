# Algorithm-pretending-to-be-AI-NaNoGenMo-2024
Creates > 50000 words of fiction algorithmically using a) text file sources and b) keywords that the user types in

This algorithm is a meld of Markov Chaining and the Cut-Up method mashed together in one algorithm. A more detailed explanation is below.

## Text sources used

The default text sources used here, stored in the `Data` folder, are 2 fiction and 2 non-fiction books from Project Gutenberg:

- [Twenty Thousand Leagues Under the Sea by Jules Verne](https://www.gutenberg.org/ebooks/164)
- [Anne of Green Gables by L.M. Montgomery](https://www.gutenberg.org/ebooks/45)
- [A Text-book of Astronomy by George C. Comstock](https://www.gutenberg.org/ebooks/34834)
- [American Rural Highways by T.R. Agg](https://www.gutenberg.org/ebooks/29420)

However, you can change the sources to whatever text you want, as described below in "Customizing the program"

## Usage - how to run this program
Please note: As a prerequisite, this code requires that `ruby` is installed on your machine. I used ruby v 3.3.0 to develop this, but have also tested it on v 3.1.2. Any 3.x of ruby should be fine.

1. First download the contents of this repository into your working directory. Then open a terminal and at the command line prompt, type `ruby generate_story.rb`

2. It will prompt you to type in your desired keywords. 

3. After that, it will generate a story using the text file sources specified in the program, in this case the 4 Project Gutenberg books mentioned above.

4. The story will be written in markdown format to a new file in the same working directory.

### Example output
You can see 2 examples of output in this repository. They differ in the keywords that were input by the user:

- [Story_bird_prey_7025.md](https://github.com/verachell/Algorithm-pretending-to-be-AI-NaNoGenMo-2024/blob/15428f573f22ba29c61dfbf8044ba07490925874/Example-output/Story_bird_prey_7025.md) - keywords: bird prey
- [Story_cold_cool_ice_1363.md](https://github.com/verachell/Algorithm-pretending-to-be-AI-NaNoGenMo-2024/blob/15428f573f22ba29c61dfbf8044ba07490925874/Example-output/Story_cold_cool_ice_1363.md) - keywords: cold cool ice

#### If your keywords are not in the source text
If none of the keywords you type in are present in the source text, the program will inform you of that and it will halt. However, if some of the keywords are present it will continue and it will inform you of which keywords it is using.

## Customizing the program for your needs
At the start of the file are the constants that you will want to change if you want to customize the behavior of the program:
```
TEXT_SOURCES = ["Data/anne-pg45.txt", "Data/leagues-pg164.txt", "Data/highways-pg29420.txt", "Data/astronomy-pg34834.txt"]
DESIRED_WORD_COUNT = 50000
COMMON_WORD_NUM = 1000
START_WORD_NUM = 400
END_WORD_NUM = 200
KW_EXACT_MATCH = true
```
You can change text sources to whatever files you want. I recommend no more than 4 books otherwise the algorithm will take a long time to run.

- `COMMON_WORD_NUM` is how many of the most common words you want to use as segmentation boundaries (see algorithm info below). The default above means we segment at each of the 1000 most common words. The smaller this number, the less segmented the text will be and the longer the average segment length will be.
- `START_WORD_NUM` is how many of the most common words you plan to use that appear at the beginning of sentences. The smaller the number, the less variety you will have in choice of start word of a sentence.
- `END_WORD_NUM` is how many of the most common words you plan to use that appear at the end of sentences. The larger the number, the shorter your sentences will become, because an end word will be encountered more frequently.
- `KW_EXACT_MATCH` when set to the default of `true` means you want your keywords to match exactly. For example, if your keyword is `hill`, it will only match `hill` and not `hilly` `chill` or `shilling`. On the other hand, when `KW_EXACT_MATCH` is set to `false`, your keyword will match anything containing that word. Sometimes this might be desirable, for example if your keyword is `horse` and you want to also match `horses` and `horseback`

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

### Ruby and operating system software used
This program was developed using ruby v 3.3.0 on a Raspberry Pi running Debian GNU/Linux 12

This program was also successfully tested on ruby v 3.1.2 on a PC running Windows 11

It has not been tested on an Apple machine
