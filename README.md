# ExampleApplicationQueueMusicPlayer

Example repository showing list of songs and shuffle button, then updating the queue to the new order.

This works fine for small numbers of items, but fails or takes minutes on larger numbers.
My library is roughly 5000 songs and trying to shuffle all songs and then update the queue with this method takes minutes.

As far as I can tell trying to use background threads, new async functions etc do not help, or I am not using them right!
