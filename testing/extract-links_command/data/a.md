---
url: /articles/post-a
title: Post A
aliases:
  - /old-articles/post-a
  - /posts/a
publish: true
---

This is post A.
It has some content.

This is a link to [Post B](/posts/b).

This link will be broken: [Post C](/posts/c), due to C not declaring it's original path as an alias.
It won't raise a warning during site generation when publishing this post (but should when publishing post C).

This link will also be broken: [Post D](/posts/d) due to D not being published.
It should raise a warning when publishing this post.

Images should work too ![Image](/assets/images/sample-image.png) and also this one ![Another Image](/assets/images/another-image.png).
