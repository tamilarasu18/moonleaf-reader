import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/chapter.dart';

/// Bundled starter library. These are short **public-domain** excerpts included
/// so the reader has real content to display out of the box. Replace or extend
/// them through [IBookRepository] when you add real book import.
final List<Book> sampleBooks = [
  Book(
    id: 'pride-and-prejudice',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    category: 'Romance',
    synopsis:
        'The spirited Elizabeth Bennet matches wits with the proud Mr. Darcy '
        'in Austen’s beloved comedy of manners, marriage and misjudgement.',
    coverGradient: const [Color(0xFF7B4B6B), Color(0xFF3A2540)],
    chapters: const [
      Chapter(
        title: 'Chapter I',
        body: '''
It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.

However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.

"My dear Mr. Bennet," said his lady to him one day, "have you heard that Netherfield Park is let at last?"

Mr. Bennet replied that he had not.

"But it is," returned she; "for Mrs. Long has just been here, and she told me all about it."

Mr. Bennet made no answer.

"Do you not want to know who has taken it?" cried his wife impatiently.

"You want to tell me, and I have no objection to hearing it."

This was invitation enough.
''',
      ),
      Chapter(
        title: 'Chapter II',
        body: '''
Mr. Bennet was among the earliest of those who waited on Mr. Bingley. He had always intended to visit him, though to the last always assuring his wife that he should not go; and till the evening after the visit was paid she had no knowledge of it.

"I hope Mr. Bingley will like it, Lizzy."

"We are not in a way to know what Mr. Bingley likes," said her mother resentfully, "since we are not to visit."

"But you forget, mamma," said Elizabeth, "that we shall meet him at the assemblies, and that Mrs. Long has promised to introduce him."
''',
      ),
    ],
  ),
  Book(
    id: 'alice-in-wonderland',
    title: "Alice's Adventures in Wonderland",
    author: 'Lewis Carroll',
    category: 'Fantasy',
    synopsis:
        'Down the rabbit-hole and into a world of riddles, talking creatures '
        'and impossible logic — Carroll’s timeless dream of curiosity.',
    coverGradient: const [Color(0xFF2F6E5B), Color(0xFF13332B)],
    chapters: const [
      Chapter(
        title: 'Down the Rabbit-Hole',
        body: '''
Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, "and what is the use of a book," thought Alice, "without pictures or conversations?"

So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her.

There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, "Oh dear! Oh dear! I shall be late!" But when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet.

In another moment down went Alice after it, never once considering how in the world she was to get out again.
''',
      ),
      Chapter(
        title: 'The Pool of Tears',
        body: '''
"Curiouser and curiouser!" cried Alice (she was so much surprised, that for the moment she quite forgot how to speak good English).

"Now I'm opening out like the largest telescope that ever was! Good-bye, feet!" (for when she looked down at her feet, they seemed to be almost out of sight, they were getting so far off).

"Oh, my poor little feet, I wonder who will put on your shoes and stockings for you now, dears? I'm sure I shan't be able!"
''',
      ),
    ],
  ),
  Book(
    id: 'sherlock-holmes',
    title: 'A Scandal in Bohemia',
    author: 'Arthur Conan Doyle',
    category: 'Mystery',
    synopsis:
        'From The Adventures of Sherlock Holmes: the great detective is outwitted '
        'by the one person he cannot forget — the woman, Irene Adler.',
    coverGradient: const [Color(0xFF3A4A63), Color(0xFF1B2433)],
    chapters: const [
      Chapter(
        title: 'I.',
        body: '''
To Sherlock Holmes she is always the woman. I have seldom heard him mention her under any other name. In his eyes she eclipses and predominates the whole of her sex. It was not that he felt any emotion akin to love for Irene Adler.

All emotions, and that one particularly, were abhorrent to his cold, precise but admirably balanced mind. He was, I take it, the most perfect reasoning and observing machine that the world has seen.

I had seen little of Holmes lately. My marriage had drifted us away from each other. One night — it was on the twentieth of March, 1888 — I was returning from a journey to a patient, when my way led me through Baker Street.

As I passed the well-remembered door, I was seized with a keen desire to see Holmes again, and to know how he was employing his extraordinary powers.
''',
      ),
      Chapter(
        title: 'II.',
        body: '''
"Wedlock suits you," he remarked. "I think, Watson, that you have put on seven and a half pounds since I saw you."

"Seven," I answered.

"Indeed, I should have thought a little more. Just a trifle more, I fancy, Watson. And in practice again, I observe. You did not tell me that you intended to go into harness."

"Then, how do you know?"

"I see it, I deduce it. How do I know that you have been getting yourself very wet lately, and that you have a most clumsy and careless servant girl?"
''',
      ),
    ],
  ),
  Book(
    id: 'frankenstein',
    title: 'Frankenstein',
    author: 'Mary Shelley',
    category: 'Gothic',
    synopsis:
        'A young scientist creates life — and recoils from his creation. '
        'Shelley’s haunting meditation on ambition, loneliness and what we owe '
        'to what we make.',
    coverGradient: const [Color(0xFF4A4A8A), Color(0xFF1E1E3A)],
    chapters: const [
      Chapter(
        title: 'Letter 1',
        body: '''
You will rejoice to hear that no disaster has accompanied the commencement of an enterprise which you have regarded with such evil forebodings. I arrived here yesterday, and my first task is to assure my dear sister of my welfare and increasing confidence in the success of my undertaking.

I am already far north of London, and as I walk in the streets of Petersburgh, I feel a cold northern breeze play upon my cheeks, which braces my nerves and fills me with delight.

Do you understand this feeling? This breeze, which has travelled from the regions towards which I am advancing, gives me a foretaste of those icy climes. Inspirited by this wind of promise, my daydreams become more fervent and vivid.
''',
      ),
      Chapter(
        title: 'Letter 2',
        body: '''
How slowly the time passes here, encompassed as I am by frost and snow! Yet a second step is taken towards my enterprise.

I have hired a vessel and am occupied in collecting my sailors; those whom I have already engaged appear to be men on whom I can depend and are certainly possessed of dauntless courage.

But I have one want which I have never yet been able to satisfy, and the absence of the object of which I now feel as a most severe evil. I have no friend, Margaret.
''',
      ),
    ],
  ),
  Book(
    id: 'wizard-of-oz',
    title: 'The Wonderful Wizard of Oz',
    author: 'L. Frank Baum',
    category: 'Adventure',
    synopsis:
        'A Kansas cyclone sweeps Dorothy and her dog Toto to the merry land of '
        'Oz, where a long road of yellow brick leads home.',
    coverGradient: const [Color(0xFF2E7D5B), Color(0xFF14402E)],
    chapters: const [
      Chapter(
        title: 'The Cyclone',
        body: '''
Dorothy lived in the midst of the great Kansas prairies, with Uncle Henry, who was a farmer, and Aunt Em, who was the farmer's wife. Their house was small, for the lumber to build it had to be carried by wagon many miles.

There were four walls, a floor and a roof, which made one room; and this room contained a rusty looking cookstove, a cupboard for the dishes, a table, three or four chairs, and the beds.

When Dorothy stood in the doorway and looked around, she could see nothing but the great gray prairie on every side. Not a tree nor a house broke the broad sweep of flat country that reached to the edge of the sky in all directions.

Today, however, the grass was not green, for the sun had baked the tops of the long blades until they were the same gray colour to be seen everywhere.
''',
      ),
      Chapter(
        title: 'The Council with the Munchkins',
        body: '''
She was awakened by a shock, so sudden and severe that if Dorothy had not been lying on the soft bed she might have been hurt. As it was, the jar made her catch her breath and wonder what had happened.

Toto put his cold little nose into her face and whined dismally. Dorothy sat up and noticed that the house was not moving; nor was it dark, for the bright sunshine came in at the window, flooding the little room.

She sprang from her bed and with Toto at her heels ran and opened the door. The little girl gave a cry of amazement and looked about her, her eyes growing bigger and bigger at the wonderful sights she saw.
''',
      ),
    ],
  ),
];
