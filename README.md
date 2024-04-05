This code is meant as companion to the article about tree caching.

Find the article [here](https://blog.julik.nl/2024/04/batch-caching-of-trees)

This proof of concept now includes 3 renderers:

* A naive, non-caching renderer (`naive_renderer.rb`)
* A depth-first caching renderer (`depth_first_renderer.rb`)
* A batched depth-first caching renderer - similar to how Rails partials and collection renders are cached now (`batched_depth_first_renderer.rb`)
* A batched breadth-first caching renderer (`batched_depth_first_renderer.rb`)

